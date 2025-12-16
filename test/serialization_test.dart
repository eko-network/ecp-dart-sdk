import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/src/types/key_request.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

// Helper to compare Uint8List
bool listsEqual(List<int>? a, List<int>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void main() {
  group('Serialization tests', () {
    final uuid = Uuid();
    final domain = Uri.parse('http://localhost:3000');

    test('Address serialization', () {
      final address = Address(uid: uuid.v4obj(), domain: domain);
      final serialized = address.serialize();
      final deserialized = Address.parse(serialized);

      expect(deserialized.uid, address.uid);
      expect(deserialized.domain, address.domain);
    });

    test('Base serialization', () {
      final base = Base(
        actor: Address(uid: uuid.v4obj(), domain: domain),
        to: Address(uid: uuid.v4obj(), domain: domain),
      );

      final json = base.toJson();
      final fromJson = Base.fromJson(json);

      expect(fromJson.actor.serialize(), base.actor.serialize());
      expect(fromJson.to.serialize(), base.to.serialize());
    });

    test('KeyBundle serialization and conversion', () {
      final identityKeyPair = generateIdentityKeyPair();
      final registrationId = generateRegistrationId(false);
      final preKey = generatePreKeys(0, 1).first;
      final signedPreKey = generateSignedPreKey(identityKeyPair, 0);
      const deviceId = 1;

      final bundle = KeyBundle(
        did: uuid.v4obj(),
        identityKey: identityKeyPair.getPublicKey().serialize(),
        registrationId: registrationId,
        preKeyId: preKey.id,
        preKey: preKey.getKeyPair().publicKey.serialize(),
        signedPreKeyId: signedPreKey.id,
        signedPreKey: signedPreKey.getKeyPair().publicKey.serialize(),
        signedPreKeySignature: signedPreKey.signature,
      );

      final json = bundle.toJson();
      final fromJson = KeyBundle.fromJson(json);

      // Check serialization/deserialization
      expect(fromJson.did, bundle.did);
      expect(listsEqual(fromJson.identityKey, bundle.identityKey), isTrue);
      expect(fromJson.registrationId, bundle.registrationId);
      expect(fromJson.preKeyId, bundle.preKeyId);
      expect(listsEqual(fromJson.preKey, bundle.preKey), isTrue);
      expect(fromJson.signedPreKeyId, bundle.signedPreKeyId);
      expect(listsEqual(fromJson.signedPreKey, bundle.signedPreKey), isTrue);
      expect(
        listsEqual(
          fromJson.signedPreKeySignature,
          bundle.signedPreKeySignature,
        ),
        isTrue,
      );

      // Check conversion to libsignal's PreKeyBundle
      // This will throw if key data is malformed, so we just check that
      // it doesn't.
      fromJson.toPreKeyBundle(deviceId);
    });

    test('KeyRequest serialization', () {
      final base = Base(
        actor: Address(uid: uuid.v4obj(), domain: domain),
        to: Address(uid: uuid.v4obj(), domain: domain),
      );
      final keyRequest = KeyRequest(base: base);
      final json = keyRequest.toJson();
      final decodedJson = jsonDecode(jsonEncode(json));
      final activity = Activity.fromJson(decodedJson);

      expect(activity, isA<KeyRequest>());
      final fromJson = activity as KeyRequest;
      expect(fromJson.base.actor.serialize(), base.actor.serialize());
      expect(fromJson.base.to.serialize(), base.to.serialize());
      expect(fromJson.type, 'KeyRequest');
    });

    test('KeyResponse serialization', () {
      final identityKeyPair = generateIdentityKeyPair();
      final registrationId = generateRegistrationId(false);
      final preKey = generatePreKeys(0, 1).first;
      final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

      final bundle = KeyBundle(
        did: uuid.v4obj(),
        identityKey: identityKeyPair.getPublicKey().serialize(),
        registrationId: registrationId,
        preKeyId: preKey.id,
        preKey: preKey.getKeyPair().publicKey.serialize(),
        signedPreKeyId: signedPreKey.id,
        signedPreKey: signedPreKey.getKeyPair().publicKey.serialize(),
        signedPreKeySignature: signedPreKey.signature,
      );

      final base = Base(
        actor: Address(uid: uuid.v4obj(), domain: domain),
        to: Address(uid: uuid.v4obj(), domain: domain),
      );
      final keyResponse = KeyResponse(base: base, bundles: [bundle]);

      final json = keyResponse.toJson();
      final decodedJson = jsonDecode(jsonEncode(json));
      final activity = Activity.fromJson(decodedJson);

      expect(activity, isA<KeyResponse>());
      final fromJson = activity as KeyResponse;
      expect(fromJson.base.actor.serialize(), base.actor.serialize());
      expect(fromJson.base.to.serialize(), base.to.serialize());
      expect(fromJson.type, 'KeyResponse');
      expect(fromJson.bundles.length, 1);
      expect(fromJson.bundles.first.did, bundle.did);
    });

    test('CiphertextMessage serialization', () async {
      // This is a simplified setup to get a CiphertextMessage
      final aliceIdentity = generateIdentityKeyPair();
      final aliceRegistrationId = generateRegistrationId(false);
      final bobIdentity = generateIdentityKeyPair();
      final bobPreKey = generatePreKeys(0, 1).first;
      final bobSignedPreKey = generateSignedPreKey(bobIdentity, 0);
      final bobStore = InMemorySignalProtocolStore(
        bobIdentity,
        generateRegistrationId(false),
      );
      await bobStore.storePreKey(bobPreKey.id, bobPreKey);
      await bobStore.storeSignedPreKey(bobSignedPreKey.id, bobSignedPreKey);

      final aliceStore = InMemorySignalProtocolStore(
        aliceIdentity,
        aliceRegistrationId,
      );
      final sessionBuilder = SessionBuilder(
        aliceStore,
        aliceStore,
        aliceStore,
        aliceStore,
        SignalProtocolAddress('bob', 1),
      );

      final preKeyBundle = PreKeyBundle(
        await bobStore.getLocalRegistrationId(),
        1,
        bobPreKey.id,
        bobPreKey.getKeyPair().publicKey,
        bobSignedPreKey.id,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentity.getPublicKey(),
      );
      await sessionBuilder.processPreKeyBundle(preKeyBundle);

      final sessionCipher = SessionCipher.fromStore(
        aliceStore,
        SignalProtocolAddress('bob', 1),
      );

      final ciphertext = await sessionCipher.encrypt(
        Uint8List.fromList(utf8.encode('test message')),
      );

      final serialized = CiphertextSerializer.serialize(ciphertext);
      final deserialized = CiphertextSerializer.deserialize(serialized);

      expect(deserialized.getType(), ciphertext.getType());
      expect(
        listsEqual(deserialized.serialize(), ciphertext.serialize()),
        isTrue,
      );
    });

    test('Note and Message serialization', () async {
      // This is a simplified setup to get a CiphertextMessage
      final aliceIdentity = generateIdentityKeyPair();
      final aliceRegistrationId = generateRegistrationId(false);
      final bobIdentity = generateIdentityKeyPair();
      final bobPreKey = generatePreKeys(0, 1).first;
      final bobSignedPreKey = generateSignedPreKey(bobIdentity, 0);
      final bobStore = InMemorySignalProtocolStore(
        bobIdentity,
        generateRegistrationId(false),
      );
      await bobStore.storePreKey(bobPreKey.id, bobPreKey);
      await bobStore.storeSignedPreKey(bobSignedPreKey.id, bobSignedPreKey);

      final aliceStore = InMemorySignalProtocolStore(
        aliceIdentity,
        aliceRegistrationId,
      );
      final sessionBuilder = SessionBuilder(
        aliceStore,
        aliceStore,
        aliceStore,
        aliceStore,
        SignalProtocolAddress('bob', 1),
      );

      final preKeyBundle = PreKeyBundle(
        await bobStore.getLocalRegistrationId(),
        1,
        bobPreKey.id,
        bobPreKey.getKeyPair().publicKey,
        bobSignedPreKey.id,
        bobSignedPreKey.getKeyPair().publicKey,
        bobSignedPreKey.signature,
        bobIdentity.getPublicKey(),
      );
      await sessionBuilder.processPreKeyBundle(preKeyBundle);

      final sessionCipher = SessionCipher.fromStore(
        aliceStore,
        SignalProtocolAddress('bob', 1),
      );

      final ciphertext = await sessionCipher.encrypt(
        Uint8List.fromList(utf8.encode('test message')),
      );

      final message = EncryptedMessage(did: uuid.v4obj(), content: ciphertext);

      final base = Base(
        actor: Address(uid: uuid.v4obj(), domain: domain),
        to: Address(uid: uuid.v4obj(), domain: domain),
      );
      final note = Note(base: base, messages: [message]);

      final json = note.toJson();
      final decodedJson = jsonDecode(jsonEncode(json));
      final activity = Activity.fromJson(decodedJson);

      expect(activity, isA<Note>());
      final fromJson = activity as Note;

      expect(fromJson.type, 'Note');
      expect(fromJson.base.actor.serialize(), base.actor.serialize());
      expect(fromJson.messages.length, 1);
      expect(fromJson.messages.first.did, message.did);
      expect(
        listsEqual(
          CiphertextSerializer.serialize(fromJson.messages.first.content),
          CiphertextSerializer.serialize(message.content),
        ),
        isTrue,
      );
    });
  });
}
