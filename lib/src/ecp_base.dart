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

  Future<List<StableActivity>> getMessages() async {
    final response = await client.get(this.me.inbox);

    final List<StableActivity> ret = [];
    final activities = jsonDecode(response.body) as List;

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
          if (m.content.getType() != CiphertextMessage.prekeyType) {
            throw Exception("Unexpected type ${m.content.getType()}");
          } else {
            final senderDid = m.from;
            final address = SignalProtocolAddress(
              senderId.toString(),
              senderDid,
            );
            final sessionCipher = _buildSessionCipher(storage, address);
            await sessionCipher.decryptWithCallback(
              m.content as PreKeySignalMessage,
              (plaintext) {
                final decodedContent = jsonDecode(utf8.decode(plaintext));
                ret.add(StableActivity.fromJson(decodedContent));
              },
            );
          }
        }
      }
    }

    return ret;
  }
}
