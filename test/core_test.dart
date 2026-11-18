import 'dart:typed_data';

import 'package:ecp/ecp.dart';
import 'package:ecp/exceptions.dart';
import 'package:test/test.dart';

class _Credentials implements MlsCredentialStore {
  MlsCredentialRecord? record;

  @override
  Future<MlsCredentialRecord?> getCredential() async => record;

  @override
  Future<void> saveCredential(MlsCredentialRecord record) async =>
      this.record = record;
}

/// Only the credential store is used by [EcpCore]'s MLS operations.
class _Storage extends Storage {
  _Storage()
    : super(
        mlsEngineConfigStore: _Unused(),
        mlsCredentialStore: _Credentials(),
        capabilitiesStore: _Unused(),
        groupStore: _Unused(),
        messageStore: _Unused(),
        processedObjectStore: _Unused(),
        approvalRequestStore: _Unused(),
        deviceChainStore: _Unused(),
      );

  @override
  Future<void> clear() async {}
}

class _Unused
    implements
        MlsEngineConfigStore,
        CapabilitiesStore,
        GroupStore,
        MessageStore,
        ProcessedObjectStore,
        ApprovalRequestStore,
        DeviceChainStore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Future<EcpCore> _device(String name) async {
  final core = EcpCore(
    storage: _Storage(),
    identity: Person.fromId(Uri.parse('https://example.test/users/$name')),
    engineConfig: MlsEngineConfig(
      dbPath: ':memory:',
      encryptionKey: Uint8List(32),
    ),
  );
  await core.open();
  return core;
}

Future<List<Uint8List>> _keyPackages(EcpCore core) async {
  final (_, batch) = await core.createIdentity(numKeyPackages: 2);
  return batch.keyPackages.map((k) => k.keyPackageBytes).toList();
}

/// [creator] makes a group with [joiner] in it, under [groupId] if given.
Future<Uint8List> _groupWith(
  EcpCore creator,
  EcpCore joiner,
  Uint8List keyPackage, {
  Uint8List? groupId,
}) async {
  final group = (await creator.createGroup(groupId)).groupId;
  final added = await creator.addMembers(group, [keyPackage]);
  await creator.engine.mergePendingCommit(groupIdBytes: group);
  await joiner.joinFromWelcome(added.welcome);
  return group;
}

Future<String?> _received(EcpCore from, EcpCore to, Uint8List group) async {
  final sent = await from.encryptActivity(
    Activity.newCreate(object: ActivityPubObject.newNote(content: 'hi')),
    group,
  );
  final processed = await to.decryptPrivateMessage(
    ciphertext: (sent.object as PrivateMessage).content,
  );
  return switch (processed) {
    ReceivedActivity(:final activity) => activity.toJson().toString(),
    _ => null,
  };
}

void main() {
  late EcpCore alice;
  late EcpCore bob;
  late List<Uint8List> bobKeys;

  setUp(() async {
    alice = await _device('alice');
    bob = await _device('bob');
    await _keyPackages(alice);
    bobKeys = await _keyPackages(bob);
  });

  tearDown(() async {
    await alice.close();
    await bob.close();
  });

  test('a device removed from a group rejoins from a new welcome', () async {
    final group = await _groupWith(alice, bob, bobKeys[0]);

    final bobKey =
        (await bob.storage.mlsCredentialStore.getCredential())!.signerPublicKey;
    final removed = await alice.removeMembers(
      group,
      await alice.memberIndicesForKey(group, bobKey),
    );
    await alice.engine.mergePendingCommit(groupIdBytes: group);
    await bob.decryptPrivateMessage(ciphertext: removed.commit);
    expect(await bob.engine.groupIsActive(groupIdBytes: group), isFalse);

    final added = await alice.addMembers(group, [bobKeys[1]]);
    await alice.engine.mergePendingCommit(groupIdBytes: group);
    await bob.joinFromWelcome(added.welcome);

    expect(await bob.engine.groupIsActive(groupIdBytes: group), isTrue);
    expect(await _received(alice, bob, group), contains('hi'));
  });

  test('a welcome to a group the device is in is refused', () async {
    final group = await _groupWith(alice, bob, bobKeys[0]);

    // anyone can make a group under an ID they know
    final mallory = await _device('mallory');
    await _keyPackages(mallory);
    await expectLater(
      _groupWith(mallory, bob, bobKeys[1], groupId: group),
      throwsA(isA<EcpException>()),
    );
    await mallory.close();

    expect(await _received(alice, bob, group), contains('hi'));
  });
}
