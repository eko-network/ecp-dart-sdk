import 'dart:async';
import 'dart:convert';

import 'package:ecp/ecp.dart';
import 'package:ecp/src/auth/auth_storage.dart';
import 'package:ecp/src/types/auth_info.dart';
import 'package:ecp/src/types/current_user_keys.dart' as userKeys;
import 'package:http/http.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class _AuthenticatedHttpClient extends BaseClient {
  final Auth _auth;
  final Client _inner;

  _AuthenticatedHttpClient(this._auth, this._inner);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers['Authorization'] =
        'Bearer ${await _auth.getValidAccessToken()}';
    final originalRequest = request;
    var response = await _inner.send(request);
    print(response.statusCode);
    if (response.statusCode == 401) {
      if (originalRequest is Request) {
        print("running in refresh on fail");
        try {
          await _auth.refreshTokens();
          final newRequest = _copyRequest(originalRequest);
          newRequest.headers['Authorization'] =
              'Bearer ${await _auth.getValidAccessToken()}';
          response = await _inner.send(newRequest);
        } catch (e) {
          // If refresh fails, return original 401 response.
          return response;
        }
      }
    }
    return response;
  }

  Request _copyRequest(Request original) {
    final request = Request(original.method, original.url)
      ..bodyBytes = original.bodyBytes
      ..encoding = original.encoding
      ..followRedirects = original.followRedirects
      ..headers.addAll(original.headers)
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    return request;
  }
}

class CurrentUserKeys extends userKeys.CurrentUserKeys {
  CurrentUserKeys({
    required super.identityKeyPair,
    required super.registrationId,
    required super.preKeys,
    required super.signedPreKey,
  });
}

class Auth {
  final String deviceName;
  final Storage ecpStorage;
  final AuthStorage _storage;
  AuthInfo? _authInfo;
  final Client _authClient = Client();
  _AuthenticatedHttpClient? _authenticatedClient;
  Client get client {
    assert(
      isAuthenticated,
      'Auth.client can only be used after a user is authenticated.',
    );
    return _authenticatedClient ??= _AuthenticatedHttpClient(this, _authClient);
  }

  Future<AuthInfo>? _refreshFuture;

  Auth(this._storage, {required this.ecpStorage, required this.deviceName});
  Future<AuthInfo?> initialize() async {
    _authInfo = await _storage.getAuthInfo();
    // Auto-refresh if expired
    if (_authInfo != null && _authInfo!.isExpired) {
      try {
        await refreshTokens();
      } on AuthException catch (e) {
        if (e.message.contains('Session expired')) {
          await clearSession();
          rethrow;
        }
        if (e.message.contains('Network error')) {
        } else {
          rethrow;
        }
      }
    }
    return _authInfo;
  }

  Future<Person> login({
    required String email,
    required String password,
    required Uri url,
  }) async {
    final sessionManager = SessionManager(storage: ecpStorage);
    final keys = await sessionManager.getCurrentUserKeys(numPreKeys: 110);
    final Map<String, dynamic> requestBody = {
      'email': email,
      'password': password,
      'deviceName': deviceName,
      ...keys.toJson(),
    };

    final response = await _authClient.post(
      url.replace(pathSegments: [...url.pathSegments, "auth", "v1", "login"]),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final person = Person.fromJson(data['actor']);
      final tokens = AuthInfo.fromJson(data, url);
      _authInfo = tokens;
      await this._storage.saveAuthInfo(tokens);
      return person;
    } else {
      throw AuthException('Login failed: ${response.body}');
    }
  }

  Future<AuthInfo> refreshTokens() async {
    // Prevent concurrent refresh requests
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final currentRefreshToken = _authInfo?.refreshToken;
    if (currentRefreshToken == null) {
      throw AuthException('No refresh token available');
    }

    _refreshFuture = _performRefresh(currentRefreshToken);

    try {
      final tokens = await _refreshFuture!;
      _authInfo = tokens;
      return tokens;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<AuthInfo> _performRefresh(String refreshToken) async {
    try {
      final response = await _authClient.post(
        _authInfo!.serverUrl.replace(
          pathSegments: [
            ..._authInfo!.serverUrl.pathSegments,
            "auth",
            "v1",
            "refresh",
          ],
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = RefreshResponse.fromJson(data);

        await _storage.handleRefresh(tokens);
        return this._authInfo!.copyWith(tokens);
      } else if (response.statusCode == 401) {
        // Only clear session if we get a 401 (unauthorized) - refresh token is invalid
        await clearSession();
        throw AuthException('Session expired. Please log in again.');
      } else {
        // For other errors (network issues, server down, etc.), don't clear session
        throw AuthException('Failed to refresh token: ${response.statusCode}');
      }
    } on ClientException catch (e) {
      // Network error (offline, connection refused, etc.)
      throw AuthException('Network error during refresh: ${e.message}');
    }
  }

  FutureOr<String> getValidAccessToken() async {
    if (_authInfo == null) {
      throw AuthException('Not authenticated');
    }

    if (_authInfo!.isExpired) {
      try {
        await refreshTokens();
      } on AuthException catch (e) {
        if (e.message.contains('Network error')) {
          print('Warning: Token expired but offline, using expired token');
        } else {
          rethrow;
        }
      }
    }

    return _authInfo!.accessToken;
  }

  Future<void> clearSession() async {
    _authInfo = null;
    _refreshFuture = null;
    await Future.wait([_storage.clear(), ecpStorage.clear()]);
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    final refreshToken = this._authInfo?.refreshToken;
    if (refreshToken != null) {
      try {
        await client.post(
          _authInfo!.serverUrl.replace(
            pathSegments: [
              ..._authInfo!.serverUrl.pathSegments,
              "auth",
              "v1",
              "logout",
            ],
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      } catch (e) {
        // Even if remote logout fails, we clear local session
        print('Logout failed on server: $e');
      }
    }
    await this.clearSession();
  }

  bool get isAuthenticated => _authInfo != null;
  AuthInfo? get info => _authInfo;
}
