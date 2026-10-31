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

  Future<(CreateGroupResult, AddMembersResult)> createGroup(
    List<Person> recipiants, {
    Uint8List? groupId,
  }) async {
    // for DM's, if exactly 1 recipient and no explicit groupId, then
    // derive a deterministic group ID and check if the DM already exists
    Uint8List? resolvedGroupId = groupId;
    if (recipiants.length == 1 && resolvedGroupId == null) {
      final dmGroupId = deriveGroupId(
        a: core.identity.id,
        b: recipiants.first.id,
      );
      final existing = await storage.groupStore.getGroupByGroupId(dmGroupId);
      if (existing != null) {
        return (
          CreateGroupResult(groupId: dmGroupId),
          AddMembersResult(commit: Uint8List(0), welcome: Uint8List(0)),
        );
      }
      resolvedGroupId = dmGroupId;
    }

    final (createGroupResult, nestedActors, ownKeys) = await (
      core.createGroup(resolvedGroupId),
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
    final addMembersResult = await core.addMembers(
      createGroupResult.groupId,
      actors,
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
        final existing = await core.memberIndicesForKey(groupId, publicKey);
        if (existing.isNotEmpty) continue;

        final keyPackage = await devices.requestKey(core.identity, device);
        final result = await core.addMembers(groupId, [keyPackage.key]);
        await _sendCommit(groupId, result.commit);
        await sendWelcomes([core.identity], result);
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
        final indices = await core.memberIndicesForKey(groupId, publicKey);
        if (indices.isEmpty) continue;

        final result = await core.removeMembers(groupId, indices);
        await _sendCommit(groupId, result.commit);
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

  /// Sends a commit that has already been merged locally to the rest of the group.
  Future<void> _sendCommit(Uint8List groupId, Uint8List commit) async {
    final members = await core.getMembers(groupId);
    final to = members.map((p) => p.id).toList();
    if (!await core.hasOtherOwnDevice(groupId)) {
      to.remove(core.identity.id);
    }
    if (to.isEmpty) return;

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
