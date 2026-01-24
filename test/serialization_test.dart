import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/src/types/encrypted_message.dart';
import 'package:ecp/src/types/key_bundle.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:test/test.dart';

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
    test('KeyBundle serialization and conversion', () {
      final identityKeyPair = generateIdentityKeyPair();
      final preKey = generatePreKeys(0, 1).first;
      final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

      final bundle = KeyBundle(
        preKeyId: preKey.id,
        preKey: preKey.getKeyPair().publicKey.serialize(),
        signedPreKeyId: signedPreKey.id,
        signedPreKey: signedPreKey.getKeyPair().publicKey.serialize(),
        signedPreKeySignature: signedPreKey.signature,
      );

      final json = bundle.toJson();
      final fromJson = KeyBundle.fromJson(json);

      // Check serialization/deserialization
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
  });
}
