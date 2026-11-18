import 'dart:async';
import 'dart:convert';
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

  final _resetsAccepted =
      StreamController<({Uri person, MlsGroupRecord? dm})>.broadcast();

  /// Users whose device reset was accepted, see [acceptDeviceReset], so
  /// unverified warnings about them are settled, with the DM that took over
  /// from the old one, if any.
  Stream<({Uri person, MlsGroupRecord? dm})> get resetsAccepted =>
      _resetsAccepted.stream;

  final _merged =
      StreamController<({Uint8List from, MlsGroupRecord into})>.broadcast();

  /// DMs folded into another DM with the same user, see [mergeDms] and
  /// [acceptDeviceReset].
  Stream<({Uint8List from, MlsGroupRecord into})> get dmsMerged =>
      _merged.stream;

  // when each group's leaves were last checked and whose of them could not
  // be, so sending can wait for a device reset to be accepted
  final _checked = <String, ({DateTime at, Set<Uri> unverified})>{};
  static const _recheckAfter = Duration(seconds: 30);

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

  /// Adds a newly approved device of the current user to every group this
  /// device is a member of, hidden ones included.
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
    for (final group in await _allGroups()) {
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

  /// Removes every leaf signed by [publicKey] from the groups this device is
  /// a member of, hidden ones included, e.g. after one of our devices is
  /// revoked.
  Future<void> removeDeviceFromGroups({required Uint8List publicKey}) async {
    final failures = <Object>[];
    for (final group in await _allGroups()) {
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
  /// Returns the users whose leaves could not be checked, see [verifyLeaves].
  Future<Set<Uri>> verifyGroup(Uint8List groupId, {Uri? addedBy}) async {
    final at = DateTime.now();
    final unverified = await verifyLeaves(
      groupId,
      await core.engine.groupMembers(groupIdBytes: groupId),
      addedBy: addedBy,
    );
    _checked[_key(groupId)] = (at: at, unverified: unverified);
    return unverified;
  }

  /// Throws an [EcpDevicesChangedException] when [groupId] has leaves of
  /// users whose device chain changed and was not accepted, checking the
  /// group again when it was last checked a while ago, so a reset is noticed
  /// before anything is sent to devices the user hasn't accepted. A check
  /// that fails throws too.
  Future<void> ensureVerified(Uint8List groupId) async {
    var checked = _checked[_key(groupId)];
    if (checked == null ||
        DateTime.now().difference(checked.at) > _recheckAfter) {
      await verifyGroup(groupId);
      checked = _checked[_key(groupId)]!;
    }
    if (checked.unverified.isNotEmpty) {
      throw EcpDevicesChangedException(groupId, checked.unverified);
    }
  }

  static String _key(Uint8List groupId) => base64Encode(groupId);

  /// Checks [leaves] of [groupId] against the device chains of the users they
  /// name, after [addedBy] added them with a commit or welcome.
  ///
  /// The group already contains them, MLS has no way to refuse a commit.
  /// Revoked and unknown leaves are removed, every member that finds them
  /// tries and the server lets one commit through. Unknown and unverified
  /// leaves are reported on [deviceWarnings]. Returns the users whose leaves
  /// are unverified, they stay until the user accepts their chain.
  Future<Set<Uri>> verifyLeaves(
    Uint8List groupId,
    List<MlsMemberInfo> leaves, {
    Uri? addedBy,
  }) async {
    // new leaves, the whole group is checked before sending again
    _checked.remove(_key(groupId));
    final ownKey =
        (await storage.mlsCredentialStore.getCredential())!.signerPublicKey;
    final checked = await devices.checkLeaves(
      leaves.where((l) => !bytesEqual(l.signatureKey, ownKey)).toList(),
    );
    final bad = checked.where((c) => c.$2 != LeafStatus.device).toList();
    final unverified = {
      for (final (leaf, status) in bad)
        if (status == LeafStatus.unverified) leafOwner(leaf),
    };
    if (bad.isEmpty) return unverified;

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
    return unverified;
  }

  /// Accepts [person]'s device chain after it was reset, see
  /// [DeviceManager.trust], and brings them back into the chats shared with
  /// them.
  ///
  /// A hidden DM they started since replaces the old DM, which hands its
  /// messages over, so the conversation carries on. Every other chat gets
  /// their new devices in place of the old ones. Hidden groups whose leaves
  /// now all check out are shown. Every group is attempted, an [EcpException]
  /// listing the failures is thrown afterwards. Returns the DM that took over,
  /// if any.
  Future<MlsGroupRecord?> acceptDeviceReset(Person person) async {
    final chain = await devices.trust(person);
    _checked.clear();
    final hidden = await storage.groupStore.getHiddenGroups();
    MlsGroupRecord? newDm;
    for (final group in hidden) {
      if (await _isDmWith(group, person) &&
          (newDm == null || group.createdAt.isAfter(newDm.createdAt))) {
        newDm = group;
      }
    }

    final failures = <Object>[];
    for (final group in await storage.groupStore.getActiveGroups()) {
      try {
        final groupId = group.groupIdBytes;
        final members = await core.getMembers(groupId);
        if (!members.any((p) => p.id == person.id)) continue;
        if (newDm != null && await _isDmWith(group, person)) {
          // their old devices in it are gone, so it is the new DM that takes
          // over, whichever group ID is lower. Left as is in MLS.
          await _merge(group, newDm);
          continue;
        }
        await _replaceDevices(groupId, person, chain);
      } catch (e) {
        failures.add(e);
      }
    }

    for (final group in hidden) {
      try {
        if ((await verifyGroup(group.groupIdBytes)).isEmpty) {
          await storage.groupStore.setGroupActive(group.groupIdBytes, true);
        }
      } catch (e) {
        failures.add(e);
      }
    }
    await mergeDms();
    _resetsAccepted.add((person: person.id, dm: newDm));
    if (failures.isNotEmpty) {
      throw EcpException(
        'Failed to bring ${person.id} back into ${failures.length} group(s)',
        cause: failures.first,
      );
    }
    return newDm;
  }

  /// Checks the hidden groups again and shows those whose leaves now all
  /// check out. The rest are reported on [deviceWarnings] again, e.g. when
  /// the welcome was processed while nothing listened or without network.
  Future<void> verifyHiddenGroups() async {
    final failures = <Object>[];
    for (final group in await storage.groupStore.getHiddenGroups()) {
      try {
        if ((await verifyGroup(group.groupIdBytes)).isEmpty) {
          await storage.groupStore.setGroupActive(group.groupIdBytes, true);
        }
      } catch (e) {
        failures.add(e);
      }
    }
    await mergeDms();
    if (failures.isNotEmpty) {
      throw EcpException(
        'Failed to verify ${failures.length} hidden group(s)',
        cause: failures.first,
      );
    }
  }

  /// Removes [person]'s leaves in [groupId] that [chain] no longer lists,
  /// then adds and welcomes the devices it lists that are missing. Devices
  /// without a key package are skipped as long as one of theirs has one.
  Future<void> _replaceDevices(
    Uint8List groupId,
    Person person,
    DeviceChain chain,
  ) async {
    Future<List<MlsMemberInfo>> leaves() async => [
      for (final m in await core.engine.groupMembers(groupIdBytes: groupId))
        if (leafOwner(m) == person.id) m,
    ];

    await _commit(groupId, () async {
      final stale = [
        for (final leaf in await leaves())
          if (chain.deviceForKey(leaf.signatureKey) == null) leaf.index,
      ];
      if (stale.isEmpty) return null;
      return (await core.removeMembers(groupId, stale)).commit;
    });

    AddMembersResult? result;
    await _commit(groupId, () async {
      final current = await leaves();
      final missing = chain.devices.where(
        (d) => !current.any((l) => bytesEqual(l.signatureKey, d.publicKey)),
      );
      final keys = <Uint8List>[];
      Object? error;
      for (final device in missing) {
        try {
          keys.add((await devices.requestKey(person, device)).key);
        } catch (e) {
          error ??= e;
        }
      }
      if (keys.isEmpty) {
        if (error != null) throw error;
        return null;
      }
      result = await core.addMembers(groupId, keys);
      return result!.commit;
    });
    if (result != null) await sendWelcomes([person], result!);
  }

  /// Whether exactly this user and [person] are members of [group].
  Future<bool> _isDmWith(MlsGroupRecord group, Person person) async =>
      await _dmPartner(group) == person.id;

  /// The other member when [group] is a DM, i.e. exactly this user and one
  /// other are members.
  Future<Uri?> _dmPartner(MlsGroupRecord group) async {
    final members = (await core.getMembers(
      group.groupIdBytes,
    )).map((p) => p.id).toSet();
    if (members.length != 2 || !members.remove(core.identity.id)) return null;
    return members.single;
  }

  /// Folds the active DMs with the same user into one, e.g. after both
  /// started one at once, or a device reset ended with one started by each.
  ///
  /// Each side keeps the DM with the lowest group ID, so both keep the same
  /// one without asking each other. The others hand over their messages and
  /// stay in MLS, what is still sent in them is stored with the one kept.
  Future<void> mergeDms() async {
    final dms = <Uri, List<MlsGroupRecord>>{};
    for (final group in await storage.groupStore.getActiveGroups()) {
      final partner = await _dmPartner(group);
      if (partner != null) dms.putIfAbsent(partner, () => []).add(group);
    }
    for (final groups in dms.values.where((g) => g.length > 1)) {
      groups.sort((a, b) => _compareIds(a.groupIdBytes, b.groupIdBytes));
      for (final group in groups.skip(1)) {
        await _merge(group, groups.first);
      }
    }
  }

  Future<void> _merge(MlsGroupRecord from, MlsGroupRecord into) async {
    await storage.messageStore.moveMessages(
      from: from.groupIdBytes,
      to: into.groupIdBytes,
    );
    await storage.groupStore.mergeGroup(
      from: from.groupIdBytes,
      into: into.groupIdBytes,
    );
    _merged.add((from: from.groupIdBytes, into: into));
  }

  static int _compareIds(Uint8List a, Uint8List b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i] - b[i];
    }
    return a.length - b.length;
  }

  Future<List<MlsGroupRecord>> _allGroups() async => [
    ...await storage.groupStore.getActiveGroups(),
    ...await storage.groupStore.getHiddenGroups(),
  ];

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
  /// one [mergeDms] keeps if they ended up with several, e.g. by both
  /// starting the DM at once.
  Future<MlsGroupRecord?> _findDm(Person person) async {
    MlsGroupRecord? found;
    for (final group in await storage.groupStore.getActiveGroups()) {
      if (await _isDmWith(group, person) &&
          (found == null ||
              _compareIds(group.groupIdBytes, found.groupIdBytes) < 0)) {
        found = group;
      }
    }
    return found;
  }

  /// Key packages for [person]'s devices. A device that can't provide one,
  /// e.g. one not opened since its key packages got too old, is skipped as
  /// long as another of theirs can.
  Future<List<KeyPackage>> _requestAllKeys({required Person person}) async {
    final chain = await devices.fetch(person);
    Object? error;
    final keys = await Future.wait(
      chain.devices
          .where((d) => d.did != activitySender.did)
          .map(
            (d) => devices
                .requestKey(person, d)
                .then<KeyPackage?>((k) => k)
                .catchError((Object e) {
                  error ??= e;
                  return null;
                }),
          ),
    );
    final found = keys.whereType<KeyPackage>().toList();
    if (found.isEmpty && error != null) throw error!;
    return found;
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
