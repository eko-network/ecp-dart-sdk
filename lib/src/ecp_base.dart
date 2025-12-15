import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/src/types/key_request.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:uuid/uuid.dart';

import 'auth.dart';
import 'authenticated_client.dart';
import 'token_storage.dart';

ECPClient get ecp => ECPClient.instance;

SessionCipher _buildSessionCipher(TokenStorage sto, SignalProtocolAddress ad) {
  return SessionCipher(
    sto.sessionStore,
    sto.preKeyStore,
    sto.signedPreKeyStore,
    sto.identityKeyStore,
    ad,
  );
}

class ECPClient {
  static ECPClient? _instance;
  static ECPClient get instance {
    assert(
      _instance != null,
      'ECP has not been initialized. Please call ECP.initialize() before using it.',
    );
    return _instance!;
  }

  late final AuthManager auth;
  late final AuthenticatedHttpClient authenticatedClient;

  final String deviceName;

  final TokenStorage tokenStorage;

  factory ECPClient({
    required TokenStorage storage,
    required String deviceName,
    http.Client? httpClient,
  }) {
    final authManager = AuthManager(
      storage: storage,
      deviceName: deviceName,
      httpClient: httpClient,
    );

    return ECPClient._(
      tokenStorage: storage,
      auth: authManager,
      authenticatedClient: AuthenticatedHttpClient(auth: authManager),
      deviceName: deviceName,
    );
  }

  ECPClient._({
    required this.tokenStorage,
    required this.auth,
    required this.authenticatedClient,
    required this.deviceName,
  });

  Stream<bool> get authStream => auth.stream;

  SignalProtocolAddress get signalProtocolAddress {
    if (!this.isAuthenticated) {
      throw StateError("signalProtocolAddress used before login");
    }
    return SignalProtocolAddress(this.uid.toString(), 1);
  }

  Address get address {
    if (!this.isAuthenticated) {
      throw StateError("Address used before login");
    }
    return Address(uid: this.uid, domain: this.baseUrl);
  }

  Uri get baseUrl {
    if (!this.isAuthenticated) {
      throw StateError("BaseUrl accessed before login");
    }
    return this.auth.currentTokens!.serverUrl;
  }

  UuidValue get did {
    if (auth.currentTokens == null) {
      throw StateError("did accessed before login");
    }
    return auth.currentTokens!.did;
  }

  bool get isAuthenticated => auth.isAuthenticated;
  UuidValue get uid {
    if (auth.currentTokens == null) {
      throw StateError("uid accessed before login");
    }
    return auth.currentTokens!.uid;
  }

  //   final response = await httpClient.get(
  //     Uri.parse('$baseUrl/api/rooms/$roomId/messages'),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body) as List<dynamic>;
  //   } else {
  //     throw Exception('Failed to get messages');
  //   }
  // }

  void dispose() {
    auth.dispose();
    authenticatedClient.close();
  }

  /// Login with credentials
  Future<void> login({
    required String email,
    required String password,
    required Uri url,
  }) async {
    await auth.login(email, password, url);
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    final refreshToken = auth.currentTokens?.refreshToken;
    if (refreshToken != null) {
      try {
        await authenticatedClient.post(
          ["auth", "v1", "logout"],
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      } catch (e) {
        // Even if remote logout fails, we clear local session
        print('Logout failed on server: $e');
      }
    }
    await auth.clearSession();
  }

  Future<Map<UuidValue, int>> _requestKeys({required Address address}) async {
    final request = KeyRequest(
      base: Base(actor: this.address, to: address),
    );

    final response = await authenticatedClient.post(
      ["api", "v1", "outbox"],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final activity = Activity.fromJson(jsonBody);
      if (activity is KeyResponse) {
        final Map<UuidValue, int> signalAddressMap = {};
        for (final bundle in activity.bundles) {
          final ldid = await tokenStorage.userStore.saveUser(
            address.uid,
            bundle.did,
          );

          signalAddressMap[bundle.did] = ldid;

          final remoteSignalAddress = SignalProtocolAddress(
            address.uid.toString(),
            ldid,
          );

          final sessionBuilder = SessionBuilder(
            tokenStorage.sessionStore,
            tokenStorage.preKeyStore,
            tokenStorage.signedPreKeyStore,
            tokenStorage.identityKeyStore,
            remoteSignalAddress,
          );

          await sessionBuilder.processPreKeyBundle(bundle.toPreKeyBundle(ldid));
        }
        return signalAddressMap;
      }

      throw Exception("Unexpected response type: ${activity.runtimeType}");
    } else {
      throw Exception(
        'Failed to request keys: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Future<void> sendMessage({
    required Address address,
    required String message,
  }) async {
    final note = Note(
      base: Base(actor: this.address, to: address),
      messages: [],
    );
    final Map<UuidValue, int> signalAddressMap =
        await tokenStorage.userStore.getUser(address.uid) ??
        await _requestKeys(address: address);
    //TODO also get users devices

    for (final MapEntry(key: did, value: ldid) in signalAddressMap.entries) {
      final sessionCipher = _buildSessionCipher(
        tokenStorage,
        SignalProtocolAddress(address.uid.toString(), ldid),
      );

      final cipherText = await sessionCipher.encrypt(
        Uint8List.fromList(utf8.encode(message)),
      );

      note.messages.add(Message(did: did, content: cipherText));
    }

    final response = await authenticatedClient.post(
      ["api", "v1", "outbox"],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(note.toJson()),
    );
    //FIXME I think this should be prepared to handle a server response of not encrypted correctly
  }

  static Future<ECPClient> initialize({
    required TokenStorage storage,
    required String deviceName,
    http.Client? httpClient,
  }) async {
    final client = ECPClient(
      storage: storage,
      deviceName: deviceName,
      httpClient: httpClient,
    );
    await client._init();
    _instance = client;
    return client;
  }

  Future<void> _init() async {
    await this.auth.initialize();
  }
}
