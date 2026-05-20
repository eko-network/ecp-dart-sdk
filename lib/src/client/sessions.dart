import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/ecp.dart';
import 'package:ecp/src/client/auth/request_authenticator.dart';
import 'package:ecp/src/client/activity_sender.dart';
import 'package:ecp/src/client/discovery.dart';
import 'package:ecp/src/client/types/server_activities.dart' as remote;

class DeviceRefreshResult {
  final Map<Uri, int> activeDevices;
  final Set<Uri> newDevices;

  const DeviceRefreshResult({
    required this.activeDevices,
    required this.newDevices,
  });
}

/// Extended class for remote session operations (requires ActivitySender)
class RemoteSessionManager {
  final ActorDiscovery actorDiscovery;
  final ActivitySender activitySender;
  final Storage storage;
  final RequestAuthenticator? requestAuthenticator;
  final MlsManager mlsManager;

  RemoteSessionManager({
    required this.storage,
    required this.activitySender,
    required this.actorDiscovery,
    this.requestAuthenticator,
    MlsManager? mlsManager,
  }) : mlsManager = mlsManager ?? MlsManager(storage: storage);

  // Pulls a users hash chain and returns their devices
  Future<Set<AddDevice>> getDevices({required Person person}) async {
    final headers = await requestAuthenticator?.call() ?? {};
    final response = await activitySender.client.get(person.devices, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get devices: ${response.statusCode}\n${response.body}',
      );
    }

    final Map<Uri, AddDevice> deviceMap = {};
    final actions = jsonDecode(response.body) as List;
    //TODO better checking
    for (final rawAction in actions) {
      final action = DeviceAction.fromJson(rawAction);
      switch (action) {
        case AddDevice():
          deviceMap[action.did] = action;
        case RevokeDevice():
          deviceMap.remove(action.did);
      }
    }

    return Set.from(deviceMap.values);
  }

  Future<DeviceRefreshResult> refreshKeys({required Person person}) async {
    final (currentDevices, realDevices) = await (
      storage.userStore.getUser(person.id).then((v) => v ?? {}),
      this.getDevices(person: person),
    ).wait;

    final realDeviceDids = realDevices.map((d) => d.did).toSet();

    await Future.wait(
      currentDevices.keys
          .where((device) => !realDeviceDids.contains(device))
          .map((device) => storage.userStore.removeDevice(device)),
    );

    final newDevices = realDevices
        .where((device) => !currentDevices.containsKey(device.did))
        .toSet();

    final newDeviceMap =
        await requestKeys(person: person, devices: newDevices);

    final activeDevices = <Uri, int>{};
    for (final did in realDeviceDids) {
      activeDevices[did] = currentDevices[did] ?? newDeviceMap[did]!;
    }

    return DeviceRefreshResult(
      activeDevices: activeDevices,
      newDevices: newDevices.map((device) => device.did).toSet(),
    );
  }

  Future<Map<Uri, int>> requestKeys({
    required Person person,
    required Set<AddDevice> devices,
  }) async {
    final deviceEntries = await Future.wait(
      devices.map((device) async {
        final takeActivity = remote.Take(
          base: remote.RemoteActivityBase(
            to: Uri.parse(device.keyCollection),
            id: null,
            actor: activitySender.me.id,
          ),
        );
        final (response, signalDid) = await (
          activitySender.sendActivity(takeActivity),
          storage.userStore.saveDevice(person.id, device.did),
        ).wait;

        // Parse the response and establish sessions
        final bundle =
            KeyPackageBundle.fromTakeResponse(jsonDecode(response.body));
        
        final groupId = mlsManager.deriveGroupId(a: activitySender.me.id, b: person.id);
        
        try {
          await mlsManager.createGroup(groupId);
        } catch (error) {
          // Assume group already exists.
        }
        await mlsManager.addMembers(groupId, [bundle.keyPackage]);

        return MapEntry(device.did, signalDid);
      }),
    );

    return Map.fromEntries(deviceEntries);
  }

  /// Request keys from another user and establish sessions
  /// Returns list of device IDs
  Future<DeviceRefreshResult> requestAllKeys({required Person person}) async {
    final devices = await getDevices(person: person);
    final deviceMap = await requestKeys(person: person, devices: devices);
    return DeviceRefreshResult(
      activeDevices: deviceMap,
      newDevices: devices.map((device) => device.did).toSet(),
    );
  }
}
