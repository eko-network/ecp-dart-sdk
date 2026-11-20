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
  final reactions = <StoredReaction>[];
  final revisions = <String?>[];

  @override
  Future<void> saveMessage(StoredMessage message) async => saved.add(message);

  @override
  Future<bool> hasMessage(Uri serverActivityId) async =>
      saved.any((m) => m.serverActivityId == serverActivityId);

  @override
  Future<StoredMessage?> getMessage(Uint8List groupId, InternalId id) async =>
      saved.where((m) => m.id == id).firstOrNull;

  void _replace(
    InternalId id, {
    String? content,
    DateTime? editedAt,
    bool deleted = false,
  }) {
    final i = saved.indexWhere((m) => m.id == id);
    final m = saved[i];
    saved[i] = StoredMessage(
      serverActivityId: m.serverActivityId,
      receivedAt: m.receivedAt,
      senderId: m.senderId,
      id: m.id,
      content: content,
      inReplyTo: m.inReplyTo,
      attachment: deleted ? [] : m.attachment,
      groupId: m.groupId,
      delivered: m.delivered,
      editedAt: editedAt ?? m.editedAt,
      deleted: deleted,
    );
  }

  @override
  Future<void> editMessage(
    Uint8List groupId,
    InternalId id, {
    required String? content,
    required DateTime editedAt,
  }) async {
    revisions.add((await getMessage(groupId, id))!.content);
    _replace(id, content: content, editedAt: editedAt);
  }

  @override
  Future<void> deleteMessage(Uint8List groupId, InternalId id) async {
    revisions.clear();
    reactions.removeWhere((r) => r.messageId == id);
    _replace(id, deleted: true);
  }

  @override
  Future<void> saveReaction(StoredReaction reaction) async {
    reactions.removeWhere(
      (r) =>
          r.messageId == reaction.messageId && r.senderId == reaction.senderId,
    );
    reactions.add(reaction);
  }

  @override
  Future<StoredReaction?> getReaction(Uint8List groupId, InternalId id) async =>
      reactions.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> deleteReaction(Uint8List groupId, InternalId id) async =>
      reactions.removeWhere((r) => r.id == id);
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
  late int sentCount;
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
    sentCount = 0;
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

  /// [activity] from alice, as the server hands it to bob. [actor] is who
  /// the server claims sent it.
  Future<WireActivity> sendActivity(Activity activity, {Uri? actor}) async {
    final sent = await alice.encryptActivity(activity, group);
    actor ??= alice.identity.id;
    return WireActivity.wireCreate(
      actor: actor,
      to: [bob.identity.id],
      object: WireObject.privateMessage(
        // the first is [objectId]
        id: Uri.parse('https://example.test/objects/${++sentCount}'),
        actor: actor,
        to: [bob.identity.id],
        content: (sent.object as PrivateMessage).content,
      ),
    );
  }

  Future<WireActivity> send(String text) => sendActivity(
    Activity.newCreate(object: ActivityPubObject.newNote(content: text)),
  );

  _Messages store() => (bob.storage as _Storage).messages;

  /// Has bob receive [note] from alice.
  Future<StoredMessage> receive(Note note) async {
    final events = await handler.handleActivities([
      await sendActivity(Activity.newCreate(object: note)),
    ]);
    return (events.single as ReceivedMessage).message;
  }

  /// A message bob sent, as stored on his device.
  StoredMessage bobsMessage() {
    final message = StoredMessage(
      serverActivityId: Uri.parse('https://example.test/objects/bob'),
      receivedAt: DateTime.now(),
      senderId: bob.identity.id,
      id: InternalId.gen(),
      content: 'mine',
      attachment: [],
      groupId: group,
    );
    store().saved.add(message);
    return message;
  }

  Uint8List ciphertext(WireActivity activity) =>
      ((activity as WireCreate).object as PrivateMessage).content;

  List<String> acksTo() => [
    for (final p in posted)
      if (p['type'] == 'Delivered') (p['to'] as List).single as String,
  ];

  test('a message is stored and unstashed', () async {
    final events = await handler.handleActivities([await send('hi')]);
    final message = (events.single as ReceivedMessage).message;

    expect(message.content, 'hi');
    expect(message.senderId, alice.identity.id);
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

    final events = await handler.handleActivities([activity]);
    final message = (events.single as ReceivedMessage).message;

    expect(message.content, 'hi');
    expect(message.senderId, alice.identity.id);
    expect(await bob.stashedMessages(), isEmpty);
    expect(acksTo(), [alice.identity.id.toString()]);
  });

  test('a stash whose inbox entry was acked is restored', () async {
    await bob.engine.processMessageStashed(
      groupIdBytes: group,
      messageBytes: ciphertext(await send('hi')),
      stashId: objectId.toString(),
    );

    final events = await handler.handleActivities([]);
    final message = (events.single as ReceivedMessage).message;

    expect(message.content, 'hi');
    expect(message.serverActivityId, objectId);
    expect(await bob.stashedMessages(), isEmpty);
    expect(posted, isEmpty);
  });

  test('the sender is who signed it, not the server\'s actor', () async {
    final events = await handler.handleActivities([
      await sendActivity(
        Activity.newCreate(object: ActivityPubObject.newNote(content: 'hi')),
        actor: bob.identity.id,
      ),
    ]);

    expect(
      (events.single as ReceivedMessage).message.senderId,
      alice.identity.id,
    );
  });

  test('a message is stored under its object id', () async {
    final note = ActivityPubObject.newNote(content: 'hi') as Note;

    final message = await receive(note);

    expect(message.id, note.id);
  });

  test('a reused object id does not replace the message', () async {
    final mine = bobsMessage();

    final events = await handler.handleActivities([
      await sendActivity(
        Activity.newCreate(
          object: ActivityPubObject.note(id: mine.id, content: 'theirs'),
        ),
      ),
    ]);

    expect(events, isEmpty);
    expect(store().saved.single.senderId, bob.identity.id);
  });

  test('the sender edits a message, keeping the old text', () async {
    final message = await receive(
      ActivityPubObject.newNote(content: 'hi') as Note,
    );

    await handler.handleActivities([
      await sendActivity(
        Activity.newUpdate(
          object: ActivityPubObject.note(id: message.id, content: 'hello'),
        ),
      ),
    ]);

    final edited = store().saved.single;
    expect(edited.content, 'hello');
    expect(edited.editedAt, isNotNull);
    expect(store().revisions, ['hi']);
  });

  test('only the sender edits or deletes a message', () async {
    final mine = bobsMessage();

    await handler.handleActivities([
      await sendActivity(
        Activity.newUpdate(
          object: ActivityPubObject.note(id: mine.id, content: 'edited'),
        ),
      ),
      await sendActivity(Activity.newDelete(object: mine.id)),
    ]);

    expect(store().saved.single.content, 'mine');
    expect(store().saved.single.deleted, isFalse);
  });

  test('the sender deletes a message for everyone', () async {
    final message = await receive(
      ActivityPubObject.newNote(content: 'hi') as Note,
    );

    await handler.handleActivities([
      await sendActivity(Activity.newDelete(object: message.id)),
    ]);

    final deleted = store().saved.single;
    expect(deleted.deleted, isTrue);
    expect(deleted.content, isNull);
  });

  test('a reaction replaces the earlier one and can be taken back', () async {
    final mine = bobsMessage();
    final first = ActivityPubObject.newEmojiReact(
      inReplyTo: mine.id,
      content: '👍',
    );

    final events = await handler.handleActivities([
      await sendActivity(Activity.newCreate(object: first)),
      await sendActivity(
        Activity.newCreate(
          object: ActivityPubObject.newEmojiReact(
            inReplyTo: mine.id,
            content: '❤️',
          ),
        ),
      ),
    ]);

    expect(events.length, 2);
    final reacted = events.last as ReceivedReaction;
    expect(reacted.message.id, mine.id);
    expect(store().reactions.single.emoji, '❤️');
    expect(store().reactions.single.senderId, alice.identity.id);

    // a Delete of the replaced reaction does nothing
    await handler.handleActivities([
      await sendActivity(Activity.newDelete(object: first.id)),
    ]);
    expect(store().reactions, hasLength(1));

    await handler.handleActivities([
      await sendActivity(Activity.newDelete(object: reacted.reaction.id)),
    ]);
    expect(store().reactions, isEmpty);
  });

  test('a reaction to an unknown message is dropped', () async {
    final events = await handler.handleActivities([
      await sendActivity(
        Activity.newCreate(
          object: ActivityPubObject.newEmojiReact(
            inReplyTo: InternalId.gen(),
            content: '👍',
          ),
        ),
      ),
    ]);

    expect(events, isEmpty);
    expect(store().reactions, isEmpty);
  });
}
