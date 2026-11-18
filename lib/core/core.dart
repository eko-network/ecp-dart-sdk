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
      (_) => runZoned(action, zoneValues: {_exclusiveZoneKey: this}),
    );
    _exclusiveTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
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
    final result = await engine.createGroupWithBuilder(
      config: await mlsConfig,
      signerBytes: credential.signerBytes,
      credentialIdentity: credential.credentialIdentity,
      signerPublicKey: credential.signerPublicKey,
      credentialBytes: credential.credentialBytes,
      groupId: groupId,
      capabilities: _capabilities(),
    );
    return result;
  }

  Future<List<Person>> getMembers(Uint8List groupId) async {
    final members = await engine.groupMembers(groupIdBytes: groupId);
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
    final members = await engine.groupMembers(groupIdBytes: groupId);
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
    final members = await engine.groupMembers(groupIdBytes: groupId);
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
    return await engine.removeMembers(
      groupIdBytes: groupId,
      signerBytes: credential.signerBytes,
      memberIndices: memberIndices,
    );
  }

  Future<AddMembersResult> addMembers(
    Uint8List groupId,
    List<Uint8List> keyPackages,
  ) async {
    final credential = (await storage.mlsCredentialStore.getCredential())!;
    return await engine.addMembers(
      groupIdBytes: groupId,
      signerBytes: credential.signerBytes,
      keyPackagesBytes: keyPackages,
    );
  }

  /// Joins the group [welcomeBytes] invites this device to. A device removed
  /// from a group still stores it, its state is dropped for the new one. One
  /// it is still in is never replaced, anyone can make a Welcome for a known
  /// group ID and would take the group over.
  Future<JoinGroupResult> joinFromWelcome(Uint8List welcomeBytes) async {
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
  Future<ProcessedPrivateMessage?> decryptPrivateMessage({
    required Uint8List ciphertext,
  }) async {
    final groupId = mlsMessageExtractGroupId(messageBytes: ciphertext);
    final before = await engine.groupMembers(groupIdBytes: groupId);
    final processed = await engine.processMessage(
      groupIdBytes: groupId,
      messageBytes: ciphertext,
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
        return ReceivedActivity(
          groupId,
          Activity.fromJson(
            jsonDecode(utf8.decode(applicationMessage)) as Map<String, dynamic>,
          ),
        );
    }
  }

  Future<WireActivity> encryptActivity(Activity activity, groupId) async {
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
  const ReceivedActivity(super.groupId, this.activity);
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
Uri leafOwner(MlsMemberInfo leaf) => Uri.parse(
  utf8.decode(MlsCredential.deserialize(bytes: leaf.credential).identity()),
);

bool _bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
