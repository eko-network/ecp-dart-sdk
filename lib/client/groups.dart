import 'dart:async';
import 'dart:typed_data';

import 'package:ecp/core/utils/bytes.dart';
import 'package:ecp/ecp.dart';

class GroupManager {
  final ActivitySender activitySender;
  final DeviceManager devices;
  final Storage storage;
  final EcpCore core;

  GroupManager({
    required this.core,
    required this.activitySender,
    required this.devices,
  }) : storage = core.storage;

  /// Applies what is waiting in the inbox, before a commit that lost its
  /// claim on an epoch is retried.
  late final Future<void> Function() catchUp;

  final _deviceWarnings = StreamController<GroupDeviceWarning>.broadcast();

  /// Leaves found in a group that can't be shown to be devices of the user
  /// they name.
  Stream<GroupDeviceWarning> get deviceWarnings => _deviceWarnings.stream;

  Future<(CreateGroupResult, AddMembersResult)> createGroup(
    List<Person> recipiants, {
    Uint8List? groupId,
  }) async {
    // a DM with someone reuses the chat this device already has with just
    // them, any other group is new
    if (recipiants.length == 1 && groupId == null) {
      final existing = await _findDm(recipiants.first);
      if (existing != null) {
        return (
          CreateGroupResult(groupId: existing.groupIdBytes),
          AddMembersResult(commit: Uint8List(0), welcome: Uint8List(0)),
        );
      }
    }

    final (nestedActors, ownKeys) = await (
      Future.wait(
        recipiants.map(
          (person) =>
              _requestAllKeys(person: person).then((v) => v.map((i) => i.key)),
        ),
      ),
      // our other devices join too, so the conversation shows up on them
      _requestOwnKeys(),
    ).wait;
    final actors = [...nestedActors.expand((i) => i), ...ownKeys];
    // nobody else is in the group yet, so its first commit needs no claim
    // and is never sent, only the welcome
    final (createGroupResult, addMembersResult) = await core.exclusive(
      () async {
        final created = await core.createGroup(groupId);
        return (created, await core.addMembers(created.groupId, actors));
      },
    );
    await (
      storage.groupStore.saveGroup(groupIdBytes: createGroupResult.groupId),
      sendWelcomes([
        ...recipiants,
        if (ownKeys.isNotEmpty) core.identity,
      ], addMembersResult),
    ).wait;
    return (createGroupResult, addMembersResult);
  }

  /// Adds a newly approved device of the current user to every active group
  /// this device is a member of.
  ///
  /// [publicKey] is the signer key the device presented when asking for
  /// approval, the device in the verified chain must match it. Every group is
  /// attempted, an [EcpException] listing the failures is thrown afterwards.
  Future<void> addOwnDevice({
    required String did,
    required Uint8List publicKey,
  }) async {
    final device = (await devices.fetch(core.identity)).deviceFor(did);
    if (device == null) {
      throw EcpException('Device $did is not an approved device');
    }
    if (!bytesEqual(device.publicKey, publicKey)) {
      throw EcpException('Device $did does not match the approved key');
    }

    final failures = <Object>[];
    for (final group in await storage.groupStore.getActiveGroups()) {
      try {
        final groupId = group.groupIdBytes;
        if ((await core.memberIndicesForKey(groupId, publicKey)).isNotEmpty) {
          continue;
        }
        AddMembersResult? result;
        await _commit(groupId, () async {
          final existing = await core.memberIndicesForKey(groupId, publicKey);
          if (existing.isNotEmpty) return null;

          final keyPackage = await devices.requestKey(core.identity, device);
          result = await core.addMembers(groupId, [keyPackage.key]);
          return result!.commit;
        });
        if (result != null) await sendWelcomes([core.identity], result!);
      } catch (e) {
        failures.add(e);
      }
    }
    if (failures.isNotEmpty) {
      throw EcpException(
        'Failed to add device $did to ${failures.length} group(s)',
        cause: failures.first,
      );
    }
  }

  /// Removes every leaf signed by [publicKey] from the active groups this
  /// device is a member of, e.g. after one of our devices is revoked.
  Future<void> removeDeviceFromGroups({required Uint8List publicKey}) async {
    final failures = <Object>[];
    for (final group in await storage.groupStore.getActiveGroups()) {
      try {
        final groupId = group.groupIdBytes;
        if ((await core.memberIndicesForKey(groupId, publicKey)).isEmpty) {
          continue;
        }
        await _commit(groupId, () async {
          final indices = await core.memberIndicesForKey(groupId, publicKey);
          if (indices.isEmpty) return null;
          return (await core.removeMembers(groupId, indices)).commit;
        });
      } catch (e) {
        failures.add(e);
      }
    }
    if (failures.isNotEmpty) {
      throw EcpException(
        'Failed to remove device from ${failures.length} group(s)',
        cause: failures.first,
      );
    }
  }

  /// Checks every leaf of [groupId], after joining it from [addedBy]'s
  /// welcome, or e.g. when the chat is opened, so devices revoked since they
  /// joined, or leaves that could not be checked when they did, are found.
  Future<void> verifyGroup(Uint8List groupId, {Uri? addedBy}) async {
    await verifyLeaves(
      groupId,
      await core.engine.groupMembers(groupIdBytes: groupId),
      addedBy: addedBy,
    );
  }

  /// Checks [leaves] of [groupId] against the device chains of the users they
  /// name, after [addedBy] added them with a commit or welcome.
  ///
  /// The group already contains them, MLS has no way to refuse a commit.
  /// Revoked and unknown leaves are removed, every member that finds them
  /// tries and the server lets one commit through. Unknown and unverified
  /// leaves are reported on [deviceWarnings].
  Future<void> verifyLeaves(
    Uint8List groupId,
    List<MlsMemberInfo> leaves, {
    Uri? addedBy,
  }) async {
    final ownKey =
        (await storage.mlsCredentialStore.getCredential())!.signerPublicKey;
    final checked = await devices.checkLeaves(
      leaves.where((l) => !bytesEqual(l.signatureKey, ownKey)).toList(),
    );
    final bad = checked.where((c) => c.$2 != LeafStatus.device).toList();
    if (bad.isEmpty) return;

    final warned = <(Uri, bool)>{
      for (final (leaf, status) in bad)
        if (status != LeafStatus.revoked)
          (leafOwner(leaf), status == LeafStatus.unverified),
    };
    for (final (owner, unverified) in warned) {
      _deviceWarnings.add(
        GroupDeviceWarning(
          groupId: groupId,
          owner: owner,
          addedBy: addedBy,
          unverified: unverified,
        ),
      );
    }

    final evict = [
      for (final (leaf, status) in bad)
        if (status != LeafStatus.unverified) leaf,
    ];
    if (evict.isNotEmpty) {
      await _commit(groupId, () async {
        // another member may have removed them while this one caught up
        final members = await core.engine.groupMembers(groupIdBytes: groupId);
        final indices = [
          for (final m in members)
            if (evict.any(
              (e) =>
                  e.index == m.index &&
                  bytesEqual(e.signatureKey, m.signatureKey),
            ))
              m.index,
        ];
        if (indices.isEmpty) return null;
        return (await core.removeMembers(groupId, indices)).commit;
      });
    }
  }

  /// Claims [groupId]'s epoch, then sends the commit [create] makes, when it
  /// still makes one.
  ///
  /// The engine merges a commit as soon as it makes it, so the claim comes
  /// first: two devices committing to the same epoch would split the group
  /// between those that applied one commit and those that applied the other.
  /// A claim that is turned down is retried after catching up on the inbox,
  /// [create] runs once this device is at the group's current epoch.
  Future<void> _commit(
    Uint8List groupId,
    Future<Uint8List?> Function() create,
  ) {
    return core.exclusive(() async {
      for (var attempt = 1; ; attempt++) {
        try {
          await activitySender.claimEpoch(
            groupId,
            await core.engine.groupEpoch(groupIdBytes: groupId),
          );
          break;
        } on EcpEpochConflictException {
          if (attempt == _claimAttempts) rethrow;
          // another device may hold the claim until its commit arrives
          await Future<void>.delayed(_claimRetryDelay * attempt);
          await catchUp();
        }
      }

      final Uint8List? commit;
      try {
        commit = await create();
      } catch (_) {
        await activitySender.releaseEpoch(groupId);
        rethrow;
      }
      if (commit == null) return activitySender.releaseEpoch(groupId);
      await _sendCommit(groupId, commit);
    });
  }

  static const _claimAttempts = 4;
  static const _claimRetryDelay = Duration(milliseconds: 250);

  /// Sends a commit that has already been merged locally to the rest of the
  /// group. It goes to the server even with nobody to deliver it to, which
  /// moves the group to the next epoch there.
  Future<void> _sendCommit(Uint8List groupId, Uint8List commit) async {
    final members = await core.getMembers(groupId);
    final to = members.map((p) => p.id).toList();
    if (!await core.hasOtherOwnDevice(groupId)) {
      to.remove(core.identity.id);
    }

    final message = PrivateMessage(
      actor: core.identity.id,
      to: to,
      content: commit,
    );
    await activitySender.sendActivity(
      WireCreate(actor: core.identity.id, to: to, object: message),
    );
  }

  Future<GroupWithMembers> getMembers(MlsGroupRecord group) async {
    final people = await core.getMembers(group.groupIdBytes);
    final List<Person> upeople = [];
    final Set<Uri> added = {};
    for (final p in people) {
      if (added.add(p.id)) {
        upeople.add(p);
      }
    }

    return (group: group, members: upeople);
  }

  /// An active group whose members are exactly this user and [person], the
  /// most recently created one if they ended up with several, e.g. by both
  /// starting the DM at once.
  Future<MlsGroupRecord?> _findDm(Person person) async {
    final want = {core.identity.id, person.id};
    MlsGroupRecord? found;
    for (final group in await storage.groupStore.getActiveGroups()) {
      final members = (await core.getMembers(
        group.groupIdBytes,
      )).map((p) => p.id).toSet();
      if (members.length == want.length && members.containsAll(want)) {
        if (found == null || group.createdAt.isAfter(found.createdAt)) {
          found = group;
        }
      }
    }
    return found;
  }

  Future<List<KeyPackage>> _requestAllKeys({required Person person}) async {
    final chain = await devices.fetch(person);
    return Future.wait(
      chain.devices
          .where((d) => d.did != activitySender.did)
          .map((d) => devices.requestKey(person, d)),
    );
  }

  /// Key packages for our other devices. A device that can't provide one is
  /// skipped rather than failing the whole group creation.
  Future<List<Uint8List>> _requestOwnKeys() async {
    final chain = await devices.fetch(core.identity);
    final keys = await Future.wait(
      chain.devices
          .where((d) => d.did != activitySender.did)
          .map(
            (d) => devices
                .requestKey(core.identity, d)
                .then<KeyPackage?>((k) => k)
                .catchError((_) => null),
          ),
    );
    return keys.whereType<KeyPackage>().map((k) => k.key).toList();
  }

  Future<void> sendWelcomes(List<Person> people, AddMembersResult res) async {
    final welcome = WelcomeMessage(
      actor: core.identity.id,
      to: people.map((p) => p.id).toList(),
      content: res.welcome,
    );
    final create = WireCreate(
      actor: core.identity.id,
      to: people.map((p) => p.id).toList(),
      object: welcome,
    );
    await activitySender.sendActivity(create);
  }
}

/// Leaves of a group that name [owner] but can't be shown to be their
/// devices.
class GroupDeviceWarning {
  final Uint8List groupId;
  final Uri owner;

  /// Who added the leaves, null when they were found by
  /// [GroupManager.verifyGroup].
  final Uri? addedBy;

  /// [owner]'s device chain changed or is invalid, so the leaves could not be
  /// checked and stay in the group. Otherwise they are not devices of
  /// [owner], and a member removes them.
  final bool unverified;

  const GroupDeviceWarning({
    required this.groupId,
    required this.owner,
    required this.addedBy,
    required this.unverified,
  });
}
