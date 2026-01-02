import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/src/types/current_user_keys.dart';
import 'package:ecp/src/types/server_activities.dart' as remote;
import 'package:ecp/src/types/encrypted_message.dart';
import 'package:ecp/src/types/key_bundle.dart';
import 'package:ecp/src/types/activities.dart';
import 'package:ecp/src/types/person.dart';
import 'package:ecp/src/storage.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

typedef ActivityWithRecipients = ({
  StableActivity activity,
  List<Uri> to,
  Uri from,
});

Future<CurrentUserKeys> getCurrentUserKeys({
  required Storage storage,
  required int numPreKeys,
}) async {
  final existingidentity = await storage.identityKeyStore
      .getIdentityKeyPairOrNull();
  if (existingidentity == null) {
    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(false);
    final preKeys = generatePreKeys(0, numPreKeys);
    final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

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

    return CurrentUserKeys(
      registrationId: registrationId,
      preKeys: preKeys,
      signedPreKey: signedPreKey,
      identityKeyPair: identityKeyPair,
    );
  } else {
    final identityKeyPair = await storage.identityKeyStore.getIdentityKeyPair();
    final registrationId = await storage.identityKeyStore
        .getLocalRegistrationId();
    final List<PreKeyRecord> preKeys = [];
    for (int i = 0; i < numPreKeys; i++) {
      preKeys.add(await storage.preKeyStore.loadPreKey(i));
    }
    final signedPreKey = await storage.signedPreKeyStore.loadSignedPreKey(0);
    return CurrentUserKeys(
      registrationId: registrationId,
      preKeys: preKeys,
      signedPreKey: signedPreKey,
      identityKeyPair: identityKeyPair,
    );
  }
}

EcpClient get ecp => EcpClient.instance;

SessionCipher _buildSessionCipher(Storage sto, SignalProtocolAddress ad) {
  return SessionCipher(
    sto.sessionStore,
    sto.preKeyStore,
    sto.signedPreKeyStore,
    sto.identityKeyStore,
    ad,
  );
}

class EcpClient {
  final http.Client client;
  final Storage storage;
  final Person me;
  final int did;
  EcpClient({
    required this.storage,
    required this.client,
    required this.me,
    required this.did,
  });
  static EcpClient? _instance;
  static EcpClient get instance {
    assert(
      _instance != null,
      'ECP has not been initialized. Please call ECP.initialize() before using it.',
    );
    return _instance!;
  }

  Future<List<int>> _requestKeys({required Person person}) async {
    final response = await client.get(person.keyBundle);

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
          storage.sessionStore,
          storage.preKeyStore,
          storage.signedPreKeyStore,
          storage.identityKeyStore,
          remoteSignalAddress,
        );

        await sessionBuilder.processPreKeyBundle(bundle.toPreKeyBundle());
        devices.add(bundle.did);
        await storage.userStore.saveUser(person.id, bundle.did);
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
    required StableActivity message,
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
    final createActivity = remote.Create(
      base: remote.RemoteActivityBase(id: null, actor: this.me.id),
      object: note,
    );
    final List<int> devices =
        await storage.userStore.getUser(person.id) ??
        await _requestKeys(person: person);

    //TODO also get users devices
    for (final did in devices) {
      final sessionCipher = _buildSessionCipher(
        storage,
        SignalProtocolAddress(person.id.toString(), did),
      );

      final cipherText = await sessionCipher.encrypt(
        Uint8List.fromList(utf8.encode(jsonEncode(message))),
      );

      note.content.add(
        EncryptedMessageEntry(to: did, from: this.did, content: cipherText),
      );
    }
    final response = await client.post(
      this.me.outbox,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(createActivity.toJson()),
    );
    //FIXME I think this should be prepared to handle a server response of not encrypted correctly
    if (response.statusCode != 201)
      throw Exception(
        "Problem sending message to server: ${response.body}\nmessage:\n${createActivity.toJson()}",
      );
  }

  Future<List<ActivityWithRecipients>> getMessages() async {
    final List<ActivityWithRecipients> ret = [];
    void _processDecryptedMessage(
      List<int> plaintext,
      EncryptedMessage object,
    ) {
      final decodedContent = jsonDecode(utf8.decode(plaintext));
      final activityJson = decodedContent as Map<String, dynamic>;
      final decryptedActivity = StableActivity.fromJson(activityJson);

      ret.add((
        activity: decryptedActivity,
        to: object.to,
        from: object.attributedTo,
      ));
    }

    final response = await client.get(this.me.inbox);

    print('getMessages response body: ${response.body}');
    final decoded = jsonDecode(response.body);
    print('getMessages decoded type: ${decoded.runtimeType}');
    print('getMessages decoded value: $decoded');
    final activities = decoded as List;

    for (final body in activities) {
      final activity = remote.ServerActivity.fromJson(
        body as Map<String, dynamic>,
      );
      final senderId = activity.base.actor;
      if (activity is remote.Create) {
        for (final m in activity.object.content) {
          if (m.to != this.did) {
            continue;
          }
          final type = m.content.getType();
          final senderDid = m.from;
          final address = SignalProtocolAddress(senderId.toString(), senderDid);
          final sessionCipher = _buildSessionCipher(storage, address);
          if (type == CiphertextMessage.prekeyType) {
            await sessionCipher.decryptWithCallback(
              m.content as PreKeySignalMessage,
              (plaintext) =>
                  _processDecryptedMessage(plaintext, activity.object),
            );
          } else if (type == CiphertextMessage.whisperType) {
            await sessionCipher.decryptFromSignalWithCallback(
              m.content as SignalMessage,
              (plaintext) =>
                  _processDecryptedMessage(plaintext, activity.object),
            );
          } else {
            throw Exception("Unexpected type $type");
          }
        }
      }
    }

    return ret;
  }

  String get _baseUrl => this.me.id.origin;

  Future<Person> getActorWithWebfinger(String username) async {
    return await getActor(await webFinger(username));
  }

  Future<Person> getActor(Uri id) async {
    final response = await client.get(id);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch');
    }
    return Person.fromJson(jsonDecode(response.body));
  }

  Future<Uri> webFinger(String username) async {
    String host;
    int? port;
    String resource;

    if (username.contains('@')) {
      final parts = username.startsWith('@')
          ? username.substring(1).split('@')
          : username.split('@');

      final hostPart = parts.last;
      if (hostPart.contains(':')) {
        final hostParts = hostPart.split(':');
        host = hostParts[0];
        port = int.tryParse(hostParts[1]);
      } else {
        host = hostPart;
      }
      resource = 'acct:${parts.join('@')}';
    } else {
      final baseUri = Uri.parse(_baseUrl);
      host = baseUri.host;
      port = baseUri.port;
      resource =
          'acct:$username@$host${port != 80 && port != 443 ? ":$port" : ""}';
    }

    final isLocal = host == '127.0.0.1' || host == 'localhost';
    final url = isLocal
        ? Uri.http(
            '$host${port != null ? ":$port" : ""}',
            '/.well-known/webfinger',
            {'resource': resource},
          )
        : Uri.https(host, '/.well-known/webfinger', {'resource': resource});

    final response = await http.get(
      url,
      headers: {'Accept': 'application/jrd+json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch WebFinger for $username: HTTP ${response.statusCode} at $url',
      );
    }

    final data = jsonDecode(response.body);
    final links = data['links'] as List<dynamic>?;

    if (links == null) {
      throw Exception('Invalid WebFinger response: No links found');
    }

    final selfLink = links.firstWhere(
      (link) => link['rel'] == 'self',
      orElse: () => throw Exception('No "self" link found'),
    );

    return Uri.parse(selfLink['href'] as String);
  }
}
