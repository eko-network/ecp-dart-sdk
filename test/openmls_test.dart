import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/core/utils/openmls_library.dart';
import 'package:openmls/openmls.dart';
import 'package:test/test.dart';

Future<MlsEngine> createEngine({required String name}) async {
  return MlsEngine.create(
    dbPath: ':memory:',
    encryptionKey: Uint8List.fromList(utf8.encode(name).length >= 32
        ? utf8.encode(name).sublist(0, 32)
        : [...utf8.encode(name), ...List.filled(32 - utf8.encode(name).length, 0)]),
  );
}

Future<({Uint8List signerBytes, Uint8List signerPublicKey, Uint8List credentialBytes, Uint8List credentialIdentity})>
    makeIdentity({required String name}) async {
  final identity = Uint8List.fromList(utf8.encode(name));
  final signer = MlsSignatureKeyPair.generate(
    ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
  );
  final signerBytes = serializeSigner(
    ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
    privateKey: signer.privateKey(),
    publicKey: signer.publicKey(),
  );
  final credential = MlsCredential.basic(identity: identity);
  return (
    signerBytes: signerBytes,
    signerPublicKey: signer.publicKey(),
    credentialBytes: credential.serialize(),
    credentialIdentity: identity,
  );
}

void main() {
  test('openmls alice sends to bob', () async {
    await initOpenmls();

    final config = MlsGroupConfig.defaultConfig(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
    );

    final aliceId = await makeIdentity(name: 'alice');
    final bobId = await makeIdentity(name: 'bob');

    final alice = await createEngine(name: 'alice');
    final bob = await createEngine(name: 'bob');

    final groupId = Uint8List.fromList(List.generate(32, (i) => i));

    // Alice creates group
    await alice.createGroup(
      config: config,
      signerBytes: aliceId.signerBytes,
      credentialIdentity: aliceId.credentialIdentity,
      signerPublicKey: aliceId.signerPublicKey,
      credentialBytes: aliceId.credentialBytes,
      groupId: groupId,
    );

    // Bob creates a key package for alice to add him
    final bobKeyPackage = await bob.createKeyPackage(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
      signerBytes: bobId.signerBytes,
      credentialIdentity: bobId.credentialIdentity,
      signerPublicKey: bobId.signerPublicKey,
      credentialBytes: bobId.credentialBytes,
    );

    // Alice adds bob to the group
    final addResult = await alice.addMembers(
      groupIdBytes: groupId,
      signerBytes: aliceId.signerBytes,
      keyPackagesBytes: [bobKeyPackage.keyPackageBytes],
    );

    // Bob joins from welcome
    await bob.joinGroupFromWelcome(
      config: config,
      welcomeBytes: addResult.welcome,
      signerBytes: bobId.signerBytes,
    );

    // Alice creates an application message
    final message = Uint8List.fromList(utf8.encode('hello from alice'));
    final encrypted = await alice.createMessage(
      groupIdBytes: groupId,
      signerBytes: aliceId.signerBytes,
      message: message,
    );

    // Bob decrypts the message
    final processed = await bob.processMessage(
      groupIdBytes: groupId,
      messageBytes: encrypted.ciphertext,
    );

    expect(processed.messageType, ProcessedMessageType.application);
    expect(utf8.decode(processed.applicationMessage!), 'hello from alice');

    // Bob sends a reply
    final reply = Uint8List.fromList(utf8.encode('hello from bob'));
    final encryptedReply = await bob.createMessage(
      groupIdBytes: groupId,
      signerBytes: bobId.signerBytes,
      message: reply,
    );

    // Alice processes the commit from bob's group operation
    final aliceProcessed = await alice.processMessage(
      groupIdBytes: groupId,
      messageBytes: encryptedReply.ciphertext,
    );

    expect(aliceProcessed.messageType, ProcessedMessageType.application);
    expect(utf8.decode(aliceProcessed.applicationMessage!), 'hello from bob');

    await alice.close();
    await bob.close();
  });
}
