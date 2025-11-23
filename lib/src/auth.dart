import 'dart:async';
import 'dart:convert';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'token_storage.dart';
import 'package:http/http.dart' as http;

class AuthManager {
  final TokenStorage storage;
  final String deviceName;
  final String deviceId;
  final http.Client httpClient;

  AuthTokens? _currentTokens;
  Future<AuthTokens>? _refreshFuture;
  final _authStateController = StreamController<bool>.broadcast();

  AuthManager({
    required this.deviceName,
    required this.storage,
    http.Client? httpClient,
    required this.deviceId,
  }) : httpClient = httpClient ?? http.Client();

  Stream<bool> get stream => _authStateController.stream;

  Future<AuthTokens?> initialize() async {
    _currentTokens = await storage.authTokenStore.getAuthTokens();

    // Auto-refresh if expired
    if (_currentTokens != null && _currentTokens!.isExpired) {
      try {
        await refreshTokens();
      } catch (e) {
        _authStateController.add(isAuthenticated);
        // If refresh fails on init, clear tokens
        await clearSession();
      }
    }
    _authStateController.add(isAuthenticated);
    return _currentTokens;
  }

  Future<AuthTokens> login(String email, String password, Uri url) async {
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'deviceName': deviceName,
      'deviceId': deviceId,
    };

    late final IdentityKeyPair identityKeyPair;
    late final int registrationId;
    late final List<PreKeyRecord> preKeys;
    late final SignedPreKeyRecord signedPreKey;
    const int numPreKeys = 110;
    final existingIdentity = await storage.identityKeyStore
        .getIdentityKeyPairOrNull();

    if (existingIdentity == null) {
      identityKeyPair = generateIdentityKeyPair();
      registrationId = generateRegistrationId(false);
      preKeys = generatePreKeys(0, numPreKeys);
      signedPreKey = generateSignedPreKey(identityKeyPair, 0);

      await storage.identityKeyStore.storeIdentityKeyPair(
        identityKeyPair,
        registrationId,
      );
      for (var p in preKeys) {
        await storage.preKeyStore.storePreKey(p.id, p);
      }
      await storage.signedPreKeyStore.storeSignedPreKey(
        signedPreKey.id,
        signedPreKey,
      );
    } else {
      identityKeyPair = await storage.identityKeyStore.getIdentityKeyPair();
      registrationId = await storage.identityKeyStore.getLocalRegistrationId();
      preKeys = [];
      for (int i = 0; i < numPreKeys; i++) {
        preKeys.add(await storage.preKeyStore.loadPreKey(i));
      }
      signedPreKey = await storage.signedPreKeyStore.loadSignedPreKey(0);
    }

    requestBody['identityKey'] = base64.encode(
      identityKeyPair.getPublicKey().serialize(),
    );
    requestBody['registrationId'] = registrationId;
    requestBody['preKeys'] = preKeys
        .map(
          (p) => {
            'id': p.id,
            'key': base64.encode(p.getKeyPair().publicKey.serialize()),
          },
        )
        .toList();
    requestBody['signedPreKey'] = {
      'id': signedPreKey.id,
      'key': base64.encode(signedPreKey.getKeyPair().publicKey.serialize()),
      'signature': base64.encode(signedPreKey.signature),
    };

    final response = await httpClient.post(
      url.replace(pathSegments: [...url.pathSegments, "auth", "v1", "login"]),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data, url);
      _currentTokens = tokens;
      await storage.authTokenStore.saveAuthTokens(tokens);
      _authStateController.add(isAuthenticated);
      return tokens;
    } else {
      throw AuthException('Login failed: ${response.body}');
    }
  }

  Future<AuthTokens> refreshTokens() async {
    // Prevent concurrent refresh requests
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final currentRefreshToken = _currentTokens?.refreshToken;
    if (currentRefreshToken == null) {
      throw AuthException('No refresh token available');
    }

    _refreshFuture = _performRefresh(currentRefreshToken);

    try {
      final tokens = await _refreshFuture!;
      return tokens;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<AuthTokens> _performRefresh(String refreshToken) async {
    final response = await httpClient.post(
      _currentTokens!.serverUrl.replace(
        pathSegments: [
          ..._currentTokens!.serverUrl.pathSegments,
          "auth",
          "v1",
          "refresh",
        ],
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(data, _currentTokens!.serverUrl);
      await storage.authTokenStore.saveAuthTokens(tokens);
      return tokens;
    } else if (response.statusCode == 401) {
      await clearSession();
      throw AuthException('Session expired. Please log in again.');
    } else {
      throw AuthException('Token refresh failed: ${response.body}');
    }
  }

  Future<String> getValidAccessToken() async {
    if (_currentTokens == null) {
      throw AuthException('Not authenticated');
    }

    if (_currentTokens!.isExpired) {
      await refreshTokens();
    }

    return _currentTokens!.accessToken;
  }

  Future<void> clearSession() async {
    _currentTokens = null;
    _refreshFuture = null;
    await storage.clear();
    _authStateController.add(isAuthenticated);
  }

  bool get isAuthenticated => _currentTokens != null;

  AuthTokens? get currentTokens => _currentTokens;
  set currentTokens(AuthTokens? value) => _currentTokens = value;

  void dispose() {
    _authStateController.close();
    httpClient.close();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
