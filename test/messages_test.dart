import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _Credentials implements MlsCredentialStore {
  MlsCredentialRecord? record;

  @override
  Future<MlsCredentialRecord?> getCredential() async => record;

  @override
  Future<void> saveCredential(MlsCredentialRecord record) async =>
      this.record = record;
}

class _Groups extends _Unused {
  @override
  Future<Uint8List?> getMergedInto(Uint8List groupIdBytes) async => null;
}

class _Messages extends _Unused {
  final saved = <StoredMessage>[];

  @override
  Future<void> saveMessage(StoredMessage message) async => saved.add(message);

  @override
  Future<bool> hasMessage(Uri serverActivityId) async =>
      saved.any((m) => m.serverActivityId == serverActivityId);
}

class _Processed extends _Unused {
  final ids = <Uri>{};

  @override
  Future<void> add(Uri id) async => ids.add(id);

  @override
  Future<bool> check(Uri id) async => ids.contains(id);
}

class _Storage extends Storage {
  _Storage()
    : super(
        mlsEngineConfigStore: _Unused(),
        mlsCredentialStore: _Credentials(),
        capabilitiesStore: _Unused(),
        groupStore: _Groups(),
        messageStore: _Messages(),
        processedObjectStore: _Processed(),
        approvalRequestStore: _Unused(),
        deviceChainStore: _Unused(),
      );

  _Messages get messages => messageStore as _Messages;

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

void main() {
  late EcpCore alice;
  late EcpCore bob;
  late Uint8List group;
  late MessageHandler handler;
  late List<Map<String, dynamic>> posted;
  final objectId = Uri.parse('https://example.test/objects/1');

  setUp(() async {
    alice = await _device('alice');
    bob = await _device('bob');
    await alice.createIdentity(numKeyPackages: 1);
    final (_, bobKeys) = await bob.createIdentity(numKeyPackages: 1);
    group = (await alice.createGroup(null)).groupId;
    final added = await alice.addMembers(group, [
      bobKeys.keyPackages.single.keyPackageBytes,
    ]);
    await alice.engine.mergePendingCommit(groupIdBytes: group);
    await bob.joinFromWelcome(added.welcome);

    posted = [];
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      posted.add(body);
      return http.Response(jsonEncode(body), 201);
    });
    final sender = ActivitySender(client: client, did: 'bob-did', core: bob);
    handler = MessageHandler(
      core: bob,
      client: client,
      activitySender: sender,
      groups: GroupManager(
        core: bob,
        activitySender: sender,
        devices: DeviceManager(core: bob, activitySender: sender),
      ),
    );
  });

  tearDown(() async {
    await alice.close();
    await bob.close();
  });

  Future<WireActivity> send(String text) async {
    final sent = await alice.encryptActivity(
      Activity.newCreate(object: ActivityPubObject.newNote(content: text)),
      group,
    );
    return WireActivity.wireCreate(
      actor: alice.identity.id,
      to: [bob.identity.id],
      object: WireObject.privateMessage(
        id: objectId,
        actor: alice.identity.id,
        to: [bob.identity.id],
        content: (sent.object as PrivateMessage).content,
      ),
    );
  }

  Uint8List ciphertext(WireActivity activity) =>
      ((activity as WireCreate).object as PrivateMessage).content;

  List<String> acksTo() => [
    for (final p in posted)
      if (p['type'] == 'Delivered') (p['to'] as List).single as String,
  ];

  test('a message is stored and unstashed', () async {
    final messages = await handler.handleActivities([await send('hi')]);

    expect(messages.single.content, 'hi');
    expect(messages.single.senderId, alice.identity.id);
    expect(await bob.stashedMessages(), isEmpty);
    expect(acksTo(), [alice.identity.id.toString()]);
  });

  test('a message the notification service decrypted is restored', () async {
    final activity = await send('hi');
    await bob.engine.processMessageStashed(
      groupIdBytes: group,
      messageBytes: ciphertext(activity),
      stashId: objectId.toString(),
    );

    final messages = await handler.handleActivities([activity]);

    expect(messages.single.content, 'hi');
    expect(messages.single.senderId, alice.identity.id);
    expect(await bob.stashedMessages(), isEmpty);
    expect(acksTo(), [alice.identity.id.toString()]);
  });

  test('a stash whose inbox entry was acked is restored', () async {
    await bob.engine.processMessageStashed(
      groupIdBytes: group,
      messageBytes: ciphertext(await send('hi')),
      stashId: objectId.toString(),
    );

    final messages = await handler.handleActivities([]);

    expect(messages.single.content, 'hi');
    expect(messages.single.serverActivityId, objectId);
    expect(await bob.stashedMessages(), isEmpty);
    expect(posted, isEmpty);
  });
}
