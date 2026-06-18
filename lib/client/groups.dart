import 'dart:convert';
import 'dart:typed_data';
import 'package:ecp/ecp.dart';

class GroupManager {
  final ActivitySender activitySender;
  final Storage storage;
  final EcpCore core;

  GroupManager({required this.core, required this.activitySender})
    : storage = core.storage;

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

    final (createGroupResult, nestedActors) = await (
      core.createGroup(resolvedGroupId),
      Future.wait(
        recipiants.map(
          (person) =>
              _requestAllKeys(person: person).then((v) => v.map((i) => i.key)),
        ),
      ),
    ).wait;
    final actors = nestedActors.expand((i) => i);
    final addMembersResult = await core.addMembers(
      createGroupResult.groupId,
      actors.toList(),
    );
    await (
      storage.groupStore.saveGroup(groupIdBytes: createGroupResult.groupId),
      sendWelcomes(recipiants, addMembersResult),
    ).wait;
    return (createGroupResult, addMembersResult);
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
    final devices = await _getDevices(person: person);
    return await _requestKeys(devices: devices);
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

  // Pulls a users hash chain and returns their devices
  Future<List<Device>> _getDevices({required Person person}) async {
    final response = await activitySender.client.get(person.devicesEndpoint);

    if (response.statusCode != 200) {
      throw EcpNetworkException(
        'Failed to get devices for ${person.id}',
        statusCode: response.statusCode,
      );
    }

    final deviceMap = <Uri, Device>{};
    for (final raw in _parseDeviceEntries(response.body)) {
      final map = Map<String, dynamic>.from(raw as Map);
      final type = map['type'] as String?;
      if (type != 'Device') {
        continue;
      }
      final device = Device.fromJson(map);
      deviceMap[device.id] = device;
    }

    return deviceMap.values.toList();
  }

  static List<dynamic> _parseDeviceEntries(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'] ?? decoded['orderedItems'];
      if (items is List) {
        return items;
      }
    }
    return [];
  }

  Future<List<KeyPackage>> _requestKeys({required List<Device> devices}) async {
    final deviceKeys = await Future.wait(
      // Exclude this device get others
      devices.where((v) => v.did != activitySender.did).map((device) async {
        final response = await activitySender.client.post(device.keyCollection);
        return KeyPackage.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }),
    );

    return deviceKeys;
  }
}
