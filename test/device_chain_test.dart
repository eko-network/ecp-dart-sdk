import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/core/utils/openmls_library.dart';
import 'package:ecp/ecp.dart';
import 'package:test/test.dart';

final alice = Person.fromId(Uri.parse('https://eko.test/users/alice'));
final bob = Person.fromId(Uri.parse('https://eko.test/users/bob'));

MlsCredentialRecord makeCredential(Person person) {
  final signer = MlsSignatureKeyPair.generate(
    ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
  );
  final identity = Uint8List.fromList(utf8.encode(person.id.toString()));
  return MlsCredentialRecord(
    credentialIdentity: identity,
    credentialBytes: MlsCredential.basic(identity: identity).serialize(),
    signerBytes: serializeSigner(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
      privateKey: signer.privateKey(),
      publicKey: signer.publicKey(),
    ),
    signerPublicKey: signer.publicKey(),
  );
}

/// Round trips through JSON like the server does.
List<DeviceChainEntry> served(List<DeviceChainEntry> entries) => entries
    .map((e) => DeviceChainEntry.fromJson(jsonDecode(jsonEncode(e.toJson()))))
    .toList();

Matcher throwsChainError(String reason) => throwsA(
  isA<EcpDeviceChainException>().having(
    (e) => e.message,
    'message',
    contains(reason),
  ),
);

void main() {
  late MlsCredentialRecord phone;
  late MlsCredentialRecord laptop;
  late List<DeviceChainEntry> entries;

  setUpAll(initOpenmls);

  setUp(() async {
    phone = makeCredential(alice);
    laptop = makeCredential(alice);
    final genesis = await DeviceChainEntry.genesis(
      actor: alice.id,
      did: 'phone',
      credential: phone,
    );
    final chain = await DeviceChain.verify(alice, [genesis]);
    final add = await chain.approve(
      did: 'laptop',
      identityKey: laptop.signerPublicKey,
      signerDid: 'phone',
      credential: phone,
    );
    entries = served([genesis, add]);
  });

  test('a chain of approvals verifies to its devices', () async {
    final chain = await DeviceChain.verify(alice, entries);
    expect(chain.devices.map((d) => d.did), ['phone', 'laptop']);
    expect(chain.deviceFor('laptop')!.publicKey, laptop.signerPublicKey);
    expect(
      chain.deviceFor('laptop')!.keyCollection,
      Uri.parse('https://eko.test/users/alice/devices/laptop/keys'),
    );
  });

  test('a revoked device is gone, and can revoke itself', () async {
    var chain = await DeviceChain.verify(alice, entries);
    final revoke = await chain.revoke(
      did: 'laptop',
      signerDid: 'laptop',
      credential: laptop,
    );
    chain = await DeviceChain.verify(alice, served([...entries, revoke]));
    expect(chain.devices.map((d) => d.did), ['phone']);
  });

  test('the server cannot append a device it signed itself', () async {
    final server = makeCredential(alice);
    // the server's device signing its own AddDevice
    final forged = await DeviceChain.verify(alice, [
      await DeviceChainEntry.genesis(
        actor: alice.id,
        did: 'server',
        credential: server,
      ),
    ]);
    final valid = await DeviceChain.verify(alice, entries);
    final json = (await forged.approve(
      did: 'server',
      identityKey: server.signerPublicKey,
      signerDid: 'server',
      credential: server,
    )).toJson();
    json['prev'] = base64Encode(valid.head);
    await expectLater(
      DeviceChain.verify(alice, [...entries, DeviceChainEntry.fromJson(json)]),
      throwsChainError('is not a device'),
    );

    // claiming to be signed by the phone without its key
    json['signer'] = 'phone';
    await expectLater(
      DeviceChain.verify(alice, [...entries, DeviceChainEntry.fromJson(json)]),
      throwsChainError('bad signature'),
    );
  });

  test('a tampered entry or broken link is rejected', () async {
    final json = entries[1].toJson();
    json['identityKey'] = base64Encode(makeCredential(alice).signerPublicKey);
    await expectLater(
      DeviceChain.verify(alice, [entries[0], DeviceChainEntry.fromJson(json)]),
      throwsChainError('bad signature'),
    );
    await expectLater(
      DeviceChain.verify(alice, [entries[1]]),
      throwsChainError('first entry'),
    );
  });

  test("another user's chain is rejected", () async {
    await expectLater(
      DeviceChain.verify(bob, entries),
      throwsChainError('signed for'),
    );
  });

  test(
    'a rolled back or replaced chain does not include the pinned head',
    () async {
      final full = await DeviceChain.verify(alice, entries);
      final prefix = await DeviceChain.verify(alice, entries.sublist(0, 1));
      expect(full.includes(prefix.head), isTrue);
      expect(prefix.includes(full.head), isFalse);

      final reset = await DeviceChain.verify(alice, [
        await DeviceChainEntry.genesis(
          actor: alice.id,
          did: 'phone',
          credential: makeCredential(alice),
        ),
      ]);
      expect(reset.includes(full.head), isFalse);
    },
  );

  test('key packages expose their signature key and identity', () async {
    final engine = await MlsEngine.create(
      dbPath: ':memory:',
      encryptionKey: Uint8List(32),
    );
    final keyPackage = await engine.createKeyPackage(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
      signerBytes: laptop.signerBytes,
      credentialIdentity: laptop.credentialIdentity,
      signerPublicKey: laptop.signerPublicKey,
      credentialBytes: laptop.credentialBytes,
    );
    final parsed = parseKeyPackage(keyPackage.keyPackageBytes);
    expect(parsed.signatureKey, laptop.signerPublicKey);
    expect(utf8.decode(parsed.identity), alice.id.toString());
  });
}
