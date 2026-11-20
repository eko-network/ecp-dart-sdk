import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/ecp.dart';
import 'utils/openmls_library.dart';

class EcpCore {
  final Storage storage;
  final MlsEngineConfig engineConfig;
  MlsGroupConfig? _mlsConfig;
  MlsEngine? _engine;
  final Person identity;

  EcpCore({
    required this.storage,
    required this.identity,
    required this.engineConfig,
    MlsGroupConfig? mlsConfig,
  }) : _mlsConfig = mlsConfig;

  Future<MlsGroupConfig> get mlsConfig async {
    if (_mlsConfig != null) return _mlsConfig!;
    final defaults = MlsGroupConfig.defaultConfig(
      ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
    );
    _mlsConfig = MlsGroupConfig(
      ciphersuite: defaults.ciphersuite,
      wireFormatPolicy: defaults.wireFormatPolicy,
      useRatchetTreeExtension: defaults.useRatchetTreeExtension,
      // the server only orders commits, a message sent just before one can
      // still arrive after it
      maxPastEpochs: 3,
      paddingSize: defaults.paddingSize,
      senderRatchetMaxOutOfOrder: defaults.senderRatchetMaxOutOfOrder,
      senderRatchetMaxForwardDistance: defaults.senderRatchetMaxForwardDistance,
      numberOfResumptionPsks: defaults.numberOfResumptionPsks,
    );
    return _mlsConfig!;
  }

  // the engine loads and saves a group around each call, so calls changing
  // groups run one at a time or they could undo each other
  Future<void> _exclusiveTail = Future.value();
  static final _exclusiveZoneKey = Object();

  /// Runs [action] once every earlier [exclusive] action has finished, or
  /// right away when called from inside one of this core's.
  Future<T> exclusive<T>(Future<T> Function() action) {
    if (identical(Zone.current[_exclusiveZoneKey], this)) return action();
    final result = _exclusiveTail.then(
      (_) => runZoned(
        () => _withEngine(action),
        zoneValues: {_exclusiveZoneKey: this},
      ),
    );
    _exclusiveTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  bool _suspended = false;

  /// Closes the engine once the running [exclusive] actions are done, and
  /// keeps it closed between the ones that come after, until [resume]. iOS
  /// ends an app that is suspended holding a lock on a file shared with its
  /// notification service, and the service needs the database meanwhile.
  Future<void> suspend() => exclusive(() async {
    _suspended = true;
    await close();
  });

  Future<void> resume() => exclusive(() async {
    _suspended = false;
    await open();
  });

  Future<T> _withEngine<T>(Future<T> Function() action) async {
    if (!_suspended) return action();
    if (_engine == null) await open();
    try {
      return await action();
    } finally {
      // resume runs suspended too
      if (_suspended) await close();
    }
  }

  Future<MlsEngine> _getEngine() async {
    if (_engine != null) return _engine!;
    await initOpenmls();
    final config = engineConfig;
    return await MlsEngine.create(
      dbPath: config.dbPath,
      encryptionKey: config.encryptionKey,
    );
  }

  Future<void> open() async {
    try {
      _engine = await _openEngine();
    } catch (e) {
      if (e.toString().contains('Encryption key verification failed')) {
        _engine = null;
        if (await File(engineConfig.dbPath).exists()) {
          await File(engineConfig.dbPath).delete();
        }
        await storage.mlsEngineConfigStore.clearConfig();
      }
      rethrow;
    }
  }

  /// Only one engine can hold the database, another one, e.g. a push
  /// handler's, can keep it for a while. Each try waits up to 5 seconds.
  Future<MlsEngine> _openEngine() async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _getEngine();
      } catch (e) {
        if (attempt == 4 || !e.toString().contains('already open')) rethrow;
      }
    }
  }

  Future<void> close() async {
    await _engine?.close();
    _engine = null;
  }

  MlsEngine get engine {
    assert(_engine != null, "open() must be called first for direct access");
    return _engine!;
  }

  /// How long a key package stays valid. The server stops handing one out a
  /// while before, see key_package_max_age in the Supabase migration.
  static const keyPackageLifetime = Duration(days: 90);

  static const _lastResortExtension = 0x000a;

  /// What this device's leaves advertise. Empty lists keep OpenMLS's
  /// defaults, but its default ciphersuites include experimental post-quantum
  /// ones, so only the one this client uses (0x0001,
  /// [MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519]) is listed.
  static MlsCapabilities _capabilities({List<int> extensions = const []}) =>
      MlsCapabilities(
        versions: Uint16List(0),
        ciphersuites: Uint16List.fromList([0x0001]),
        extensions: Uint16List.fromList(extensions),
        proposals: Uint16List(0),
        credentials: Uint16List(0),
      );

  Future<(MlsCredentialRecord, KeyPackageBatch)> createIdentity({
    int numKeyPackages = 50,
  }) async {
    final credentialIdentity = utf8.encode(identity.id.toString());
    final storedRecord = await storage.mlsCredentialStore.getCredential();
    final MlsCredentialRecord record;
    if (storedRecord != null) {
      record = storedRecord;
    } else {
      final signer = MlsSignatureKeyPair.generate(
        ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
      );
      final credential = MlsCredential.basic(identity: credentialIdentity);
      final credentialBytes = credential.serialize();
      final signerBytes = serializeSigner(
        ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
        privateKey: signer.privateKey(),
        publicKey: signer.publicKey(),
      );
      final signerPublicKey = signer.publicKey();
      record = MlsCredentialRecord(
        credentialIdentity: credentialIdentity,
        credentialBytes: credentialBytes,
        signerBytes: signerBytes,
        signerPublicKey: signerPublicKey,
      );
      await storage.mlsCredentialStore.saveCredential(record);
    }
    return (record, await createKeyPackages(count: numKeyPackages));
  }

  /// [count] key packages that are each used once, and a last resort one that
  /// is handed out again once they run out. Unlike the others, joining a
  /// group with it keeps its private key, so it can be used more than once.
  Future<KeyPackageBatch> createKeyPackages({int count = 50}) async {
    final record = (await storage.mlsCredentialStore.getCredential())!;
    Future<KeyPackageResult> create({required bool lastResort}) =>
        engine.createKeyPackageWithOptions(
          ciphersuite: MlsCiphersuite.mls128DhkemX25519Aes128GcmSha256Ed25519,
          signerBytes: record.signerBytes,
          credentialIdentity: record.credentialIdentity,
          signerPublicKey: record.signerPublicKey,
          credentialBytes: record.credentialBytes,
          options: KeyPackageOptions(
            lifetimeSeconds: BigInt.from(keyPackageLifetime.inSeconds),
            lastResort: lastResort,
            // the leaf has to support the last_resort extension (RFC 9420
            // 17.3) it carries
            capabilities: _capabilities(
              extensions: lastResort ? const [_lastResortExtension] : const [],
            ),
          ),
        );
    return exclusive(() async {
      final keyPackages = <KeyPackageResult>[];
      for (var i = 0; i < count; i++) {
        keyPackages.add(await create(lastResort: false));
      }
      return (
        keyPackages: keyPackages,
        lastResort: await create(lastResort: true),
      );
    });
  }

  Future<CreateGroupResult> createGroup(Uint8List? groupId) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final config = await mlsConfig;
    return exclusive(
      () => engine.createGroupWithBuilder(
        config: config,
        signerBytes: credential.signerBytes,
        credentialIdentity: credential.credentialIdentity,
        signerPublicKey: credential.signerPublicKey,
        credentialBytes: credential.credentialBytes,
        groupId: groupId,
        capabilities: _capabilities(),
      ),
    );
  }

  Future<List<MlsMemberInfo>> groupMembers(Uint8List groupId) =>
      exclusive(() => engine.groupMembers(groupIdBytes: groupId));

  Future<BigInt> groupEpoch(Uint8List groupId) =>
      exclusive(() => engine.groupEpoch(groupIdBytes: groupId));

  Future<List<Person>> getMembers(Uint8List groupId) async {
    final members = await groupMembers(groupId);
    final people = members.map((m) => Person.fromId(leafOwner(m)));
    final List<Person> upeople = [];
    final Set<Uri> added = {};
    for (final p in people) {
      if (added.add(p.id)) {
        upeople.add(p);
      }
    }

    return upeople;
  }

  /// Whether a device other than this one with the same identity is a member of [groupId].
  Future<bool> hasOtherOwnDevice(Uint8List groupId) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final members = await groupMembers(groupId);
    final me = identity.id;
    return members.any(
      (m) =>
          !_bytesEqual(m.signatureKey, credential.signerPublicKey) &&
          leafOwner(m) == me,
    );
  }

  /// Leaf indices of the members whose signature key is [signatureKey].
  Future<List<int>> memberIndicesForKey(
    Uint8List groupId,
    Uint8List signatureKey,
  ) async {
    final members = await groupMembers(groupId);
    return members
        .where((m) => _bytesEqual(m.signatureKey, signatureKey))
        .map((m) => m.index)
        .toList();
  }

  Future<CommitResult> removeMembers(
    Uint8List groupId,
    List<int> memberIndices,
  ) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    return exclusive(
      () => engine.removeMembers(
        groupIdBytes: groupId,
        signerBytes: credential.signerBytes,
        memberIndices: memberIndices,
      ),
    );
  }

  Future<AddMembersResult> addMembers(
    Uint8List groupId,
    List<Uint8List> keyPackages,
  ) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    return exclusive(
      () => engine.addMembers(
        groupIdBytes: groupId,
        signerBytes: credential.signerBytes,
        keyPackagesBytes: keyPackages,
      ),
    );
  }

  /// Joins the group [welcomeBytes] invites this device to. A device removed
  /// from a group still stores it, its state is dropped for the new one. One
  /// it is still in is never replaced, anyone can make a Welcome for a known
  /// group ID and would take the group over.
  Future<JoinGroupResult> joinFromWelcome(Uint8List welcomeBytes) =>
      exclusive(() => _joinFromWelcome(welcomeBytes));

  Future<JoinGroupResult> _joinFromWelcome(Uint8List welcomeBytes) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final config = await mlsConfig;
    final groupId = (await engine.inspectWelcome(
      config: config,
      welcomeBytes: welcomeBytes,
    )).groupId;
    final stored = await engine.groupIds();
    if (stored.any((id) => _bytesEqual(id, groupId))) {
      if (await engine.groupIsActive(groupIdBytes: groupId)) {
        throw const EcpException('Welcome to a group this device is in');
      }
      await engine.deleteGroup(groupIdBytes: groupId);
    }
    return await engine.joinGroupFromWelcome(
      config: config,
      welcomeBytes: welcomeBytes,
      signerBytes: credential.signerBytes,
    );
  }

  /// Process a [PrivateMessage] MLS ciphertext: decrypt an application
  /// message, or merge a commit. Null for a proposal.
  ///
  /// With [stashId] an application message is also kept under it until
  /// [deleteStashed], written with the ratchet that deletes its key, so a
  /// process that ends before the message is stored can't lose it.
  Future<ProcessedPrivateMessage?> decryptPrivateMessage({
    required Uint8List ciphertext,
    String? stashId,
  }) => exclusive(() => _decryptPrivateMessage(ciphertext, stashId));

  Future<ProcessedPrivateMessage?> _decryptPrivateMessage(
    Uint8List ciphertext,
    String? stashId,
  ) async {
    final groupId = mlsMessageExtractGroupId(messageBytes: ciphertext);
    final before = await engine.groupMembers(groupIdBytes: groupId);
    final processed = stashId == null
        ? await engine.processMessage(
            groupIdBytes: groupId,
            messageBytes: ciphertext,
          )
        : await engine.processMessageStashed(
            groupIdBytes: groupId,
            messageBytes: ciphertext,
            stashId: stashId,
          );

    switch (processed.messageType) {
      // processMessage already merged it. Merging again would fail for a
      // commit that removed this device, the group is inactive after it.
      case ProcessedMessageType.stagedCommit:
        final after = await engine.groupMembers(groupIdBytes: groupId);
        final committer = before
            .where((m) => m.index == processed.senderIndex)
            .firstOrNull;
        return MergedCommit(
          groupId,
          committer: committer == null ? null : leafOwner(committer),
          newLeaves: after
              .where(
                (m) => !before.any(
                  (b) =>
                      b.index == m.index &&
                      _bytesEqual(b.signatureKey, m.signatureKey) &&
                      _bytesEqual(b.credential, m.credential),
                ),
              )
              .toList(),
        );
      case ProcessedMessageType.proposal:
        // I don't know if this requires action or not
        return null;
      case ProcessedMessageType.application:
        final applicationMessage = processed.applicationMessage;
        if (applicationMessage == null) {
          return null;
        }
        // the server's actor is only a claim, the leaf signed the message
        final sender = before
            .where((m) => m.index == processed.senderIndex)
            .firstOrNull;
        if (sender == null) {
          throw EcpException('application message from an unknown leaf');
        }
        return ReceivedActivity(
          groupId,
          Activity.fromJson(
            jsonDecode(utf8.decode(applicationMessage)) as Map<String, dynamic>,
          ),
          sender: leafOwner(sender),
        );
    }
  }

  /// Messages decrypted with a stash id that were not deleted yet, by this
  /// device's app or its iOS notification service, oldest first.
  Future<List<StashedMessage>> stashedMessages() =>
      exclusive(() => engine.stashedMessages());

  Future<StashedMessage?> stashedMessage(String stashId) =>
      exclusive(() => engine.stashedMessage(stashId: stashId));

  Future<void> deleteStashed(String stashId) =>
      exclusive(() => engine.deleteStashedMessage(stashId: stashId));

  Future<WireActivity> encryptActivity(Activity activity, groupId) =>
      exclusive(() => _encryptActivity(activity, groupId));

  Future<WireActivity> _encryptActivity(Activity activity, groupId) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    final content = await engine.createMessage(
      groupIdBytes: groupId,
      signerBytes: credential.signerBytes,
      message: utf8.encode(jsonEncode(activity.toJson())),
    );
    final recipinants = (await getMembers(
      groupId,
    ).then((ps) => ps.map((p) => p.id))).toList();
    // only address ourselves when another of our devices is in the group, the
    // server never echoes an activity back to the sending device
    if (!await hasOtherOwnDevice(groupId)) {
      recipinants.removeWhere((u) => u == identity.id);
    }
    final message = PrivateMessage(
      actor: identity.id,
      to: recipinants,
      content: content.ciphertext,
    );
    return WireCreate(to: recipinants, object: message, actor: identity.id);
  }
}

/// What a [PrivateMessage] turned out to carry once processed.
sealed class ProcessedPrivateMessage {
  final Uint8List groupId;
  const ProcessedPrivateMessage(this.groupId);
}

final class ReceivedActivity extends ProcessedPrivateMessage {
  final Activity activity;

  /// The user whose device sent it.
  final Uri sender;
  const ReceivedActivity(super.groupId, this.activity, {required this.sender});
}

/// A commit, already merged: MLS has no way to refuse one without falling
/// out of the group.
final class MergedCommit extends ProcessedPrivateMessage {
  /// The user whose device sent the commit, null for an external commit.
  final Uri? committer;

  /// Leaves the commit added, or whose signature key or credential it
  /// changed, which have not been checked against their owners' chains.
  final List<MlsMemberInfo> newLeaves;

  const MergedCommit(
    super.groupId, {
    required this.committer,
    required this.newLeaves,
  });
}

/// The user a leaf's basic credential names.
Uri leafOwner(MlsMemberInfo leaf) => credentialOwner(leaf.credential);

/// The user a TLS-serialized basic credential names.
Uri credentialOwner(Uint8List credential) => Uri.parse(
  utf8.decode(MlsCredential.deserialize(bytes: credential).identity()),
);

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
