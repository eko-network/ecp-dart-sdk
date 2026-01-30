import 'package:ecp/ecp.dart';
import 'package:ecp/src/parts/discovery.dart';
import 'package:ecp/src/parts/activity_sender.dart';
import 'package:ecp/src/types/device_actions.dart';
import 'package:ecp/src/types/server_activities.dart' as remote;
import 'dart:convert';

/// Base class for local session operations (no network access required)
class SessionManager {
  final Storage storage;

  SessionManager({required this.storage});

  /// Get or generate current user's keys
  Future<CurrentUserKeys> getCurrentUserKeys({required int numPreKeys}) async {
    final existingIdentity = await storage.identityKeyStore
        .getIdentityKeyPairOrNull();

    if (existingIdentity == null) {
      // Generate new keys
      final identityKeyPair = generateIdentityKeyPair();
      final registrationId = generateRegistrationId(false);
      final preKeys = generatePreKeys(0, numPreKeys);
      final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

      // Store generated keys
      await storage.identityKeyStore.storeIdentityKeyPair(
        identityKeyPair,
        registrationId,
      );
      for (var p in preKeys) {
        await storage.preKeyStore.storePreKey(p.id, p);
      }
      await storage.signedPreKeyStore.storeSignedPreKey(
        signedPreKey.id,
        signedPreKey,
      );

      return CurrentUserKeys(
        registrationId: registrationId,
        preKeys: preKeys,
        signedPreKey: signedPreKey,
        identityKeyPair: identityKeyPair,
      );
    } else {
      // Load existing keys
      final identityKeyPair = await storage.identityKeyStore
          .getIdentityKeyPair();
      final registrationId = await storage.identityKeyStore
          .getLocalRegistrationId();
      final List<PreKeyRecord> preKeys = [];
      for (int i = 0; i < numPreKeys; i++) {
        preKeys.add(await storage.preKeyStore.loadPreKey(i));
      }
      final signedPreKey = await storage.signedPreKeyStore.loadSignedPreKey(0);

      return CurrentUserKeys(
        registrationId: registrationId,
        preKeys: preKeys,
        signedPreKey: signedPreKey,
        identityKeyPair: identityKeyPair,
      );
    }
  }
}

/// Extended class for remote session operations (requires ActivitySender)
class RemoteSessionManager {
  final ActorDiscovery actorDiscovery;
  final ActivitySender activitySender;
  final Storage storage;

  RemoteSessionManager({
    required this.storage,
    required this.activitySender,
    required this.actorDiscovery,
  });

  // Pulls a users hash chain and returns their devices
  Future<Set<AddDevice>> getDevices({required Person person}) async {
    final response = await activitySender.client.get(person.devices);

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

  /// Build a session cipher for a specific address
  SessionCipher buildSessionCipher(SignalProtocolAddress address) {
    return SessionCipher(
      storage.sessionStore,
      storage.preKeyStore,
      storage.signedPreKeyStore,
      storage.identityKeyStore,
      address,
    );
  }

  Future<Map<Uri, int>> refreshKeys({required Person person}) async {
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

    final newDeviceMap = await requestKeys(person: person, devices: newDevices);

    final activeDevices = <Uri, int>{};
    for (final did in realDeviceDids) {
      activeDevices[did] = currentDevices[did] ?? newDeviceMap[did]!;
    }

    return activeDevices;
  }

  Future<Map<Uri, int>> requestKeys({
    required Person person,
    required Set<AddDevice> devices,
  }) async {
    final deviceEntries = await Future.wait(
      devices.map((device) async {
        final takeActivity = remote.Take(
          base: remote.RemoteActivityBase(
            id: null,
            actor: activitySender.me.id,
          ),
          target: Uri.parse(device.keyCollection),
        );
        final (response, signalDid) = await (
          activitySender.sendActivity(takeActivity),
          storage.userStore.saveDevice(person.id, device.did),
        ).wait;

        // Parse the response and establish sessions
        final bundle = KeyBundle.fromJson(jsonDecode(response.body));
        final remoteAddress = SignalProtocolAddress(
          person.id.toString(),
          signalDid,
        );

        final sessionBuilder = SessionBuilder(
          storage.sessionStore,
          storage.preKeyStore,
          storage.signedPreKeyStore,
          storage.identityKeyStore,
          remoteAddress,
        );

        await sessionBuilder.processPreKeyBundle(
          bundle.toPreKeyBundle(
            registrationId: device.registrationId,
            identityKey: device.identityKey,
            did: signalDid,
          ),
        );

        return MapEntry(device.did, signalDid);
      }),
    );

    return Map.fromEntries(deviceEntries);
  }

  /// Request keys from another user and establish sessions
  /// Returns list of device IDs
  Future<Map<Uri, int>> requestAllKeys({required Person person}) async {
    final devices = await getDevices(person: person);
    return await requestKeys(person: person, devices: devices);
  }
}
