import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/src/types/create_activity.dart';
import 'package:ecp/src/types/encrypted_message.dart';
import 'package:ecp/src/types/key_bundle.dart';
import 'package:ecp/src/types/message.dart';
import 'package:ecp/src/types/person.dart';
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

  Person? _me;
  Person get me {
    if (!this.isAuthenticated) {
      throw StateError("me accessed before login");
    }
    return _me!;
  }

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

  // Address get address {
  //   if (!this.isAuthenticated) {
  //     throw StateError("Address used before login");
  //   }
  //   return Address(uid: this.uid, domain: this.baseUrl);
  // }

  Uri get baseUrl {
    if (!this.isAuthenticated) {
      throw StateError("BaseUrl accessed before login");
    }
    return this.auth.currentTokens!.serverUrl;
  }

  int get did {
    if (auth.currentTokens == null) {
      throw StateError("did accessed before login");
    }
    return auth.currentTokens!.did;
  }

  bool get isAuthenticated => auth.isAuthenticated;
  String get uid {
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
    _me = await auth.login(email, password, url);
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

  Future<List<int>> _requestKeys({required Person person}) async {
    final response = await authenticatedClient.get(
      person.keyBundle.pathSegments,
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body) as List;
      final List<int> devices = [];
      for (final obj in jsonBody) {
        final bundle = KeyBundle.fromJson(obj);
        final remoteSignalAddress = SignalProtocolAddress(
          person.id.toString(),
          bundle.did,
        );

        final sessionBuilder = SessionBuilder(
          tokenStorage.sessionStore,
          tokenStorage.preKeyStore,
          tokenStorage.signedPreKeyStore,
          tokenStorage.identityKeyStore,
          remoteSignalAddress,
        );

        await sessionBuilder.processPreKeyBundle(bundle.toPreKeyBundle());
        devices.add(bundle.did);
      }
      return devices;
    } else {
      throw Exception(
        'Failed to request keys: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Future<void> sendMessage({
    required Person person,
    required String message,
  }) async {
    final note = EncryptedMessage(
      context: [
        "https://www.w3.org/ns/activitystreams",
        {'sec': "our context"},
      ],
      typeField: 'EncryptedMessage',
      id: null,
      content: [],
      attributedTo: this.me.id,
      to: [person.id],
    );
    final createActivity = CreateActivity(
      context: "https://www.w3.org/ns/activitystreams",
      typeField: "Create",
      id: null,
      actor: this.me.id,
      object: note,
    );
    final List<int> devices =
        await tokenStorage.userStore.getUser(person.id) ??
        await _requestKeys(person: person);

    //TODO also get users devices
    for (final did in devices) {
      final sessionCipher = _buildSessionCipher(
        tokenStorage,
        SignalProtocolAddress(person.id.toString(), did),
      );

      final cipherText = await sessionCipher.encrypt(
        Uint8List.fromList(utf8.encode(message)),
      );

      note.content.add(
        EncryptedMessageEntry(to: did, from: this.did, content: cipherText),
      );
    }
    final response = await authenticatedClient.post(
      this.me.outbox.pathSegments,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(createActivity.toJson()),
    );
    //FIXME I think this should be prepared to handle a server response of not encrypted correctly
    if (response.statusCode != 201)
      throw Exception(
        "Problem sending message to server: ${response.body}\nmessage:\n${createActivity.toJson()}",
      );
  }

  Future<List<Message>> getMessages() async {
    final response = await authenticatedClient.get(this.me.inbox.pathSegments);

    final List<Message> ret = [];
    final activities = jsonDecode(response.body) as List;

    for (final body in activities) {
      final activity = CreateActivity.fromJson(body as Map<String, dynamic>);
      final senderId = activity.object.attributedTo;
      for (final m in activity.object.content) {
        if (m.to != this.did) {
          continue;
        }
        if (m.content.getType() != CiphertextMessage.prekeyType) {
          throw Exception("Unexpected type ${m.content.getType()}");
        } else {
          final senderDid = m.from;
          final address = SignalProtocolAddress(senderId.toString(), senderDid);
          final sessionCipher = _buildSessionCipher(tokenStorage, address);
          await sessionCipher.decryptWithCallback(
            m.content as PreKeySignalMessage,
            (plaintext) {
              final decodedContent = utf8.decode(plaintext);
              ret.add(
                Message(
                  id: activity.id!,
                  to: activity.object.to.first,
                  from: activity.object.attributedTo,
                  content: decodedContent,
                ),
              );
            },
          );
        }
      }
    }

    return ret;
  }

  // Future<Uri> queryWebFinger(Address address) async {
  //   throw UnimplementedError();
  //   final response = await authenticatedClient.get([
  //     ".well-known",
  //     "webfinger",
  //   ]);
  // }

  // Future<void> getActor(Uri id) async {
  //   final response = await authenticatedClient.get(id.pathSegments);
  // }

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
