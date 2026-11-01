import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/core/utils/bytes.dart';
import 'package:ecp/ecp.dart';

/// Fetches and verifies users' device chains, and signs the entries this
/// device adds to its own user's chain.
///
/// Only devices listed in a verified chain, and only key packages signed by
/// such a device's key, are ever added to a group, so the server cannot slip
/// in a device of its own.
class DeviceManager {
  final EcpCore core;
  final ActivitySender activitySender;

  DeviceManager({required this.core, required this.activitySender});

  /// [person]'s verified device chain.
  ///
  /// The chain has to extend the head pinned from the last fetch, otherwise
  /// an [EcpDeviceChainChangedException] is thrown until the new chain is
  /// accepted with [trust]. The first chain seen for a user is trusted.
  Future<DeviceChain> fetch(Person person) async {
    final chain = await DeviceChain.verify(person, await _fetchEntries(person));
    final store = core.storage.deviceChainStore;
    final pinned = await store.getPinnedHead(person.id);
    if (pinned != null && !chain.includes(pinned)) {
      throw EcpDeviceChainChangedException(person.id);
    }
    await store.pinHead(person.id, chain.head);
    return chain;
  }

  /// Accepts [person]'s current chain even though it does not extend the
  /// pinned one, e.g. after the user confirmed their contact reset devices.
  Future<DeviceChain> trust(Person person) async {
    final chain = await DeviceChain.verify(person, await _fetchEntries(person));
    await core.storage.deviceChainStore.pinHead(person.id, chain.head);
    return chain;
  }

  /// How each of [leaves] of a group holds up against the device chain of
  /// the user it names.
  Future<List<(MlsMemberInfo, LeafStatus)>> checkLeaves(
    List<MlsMemberInfo> leaves,
  ) async {
    final byOwner = <Uri, List<MlsMemberInfo>>{};
    for (final leaf in leaves) {
      byOwner.putIfAbsent(leafOwner(leaf), () => []).add(leaf);
    }

    final results = <(MlsMemberInfo, LeafStatus)>[];
    for (final MapEntry(key: owner, value: ownerLeaves) in byOwner.entries) {
      final DeviceChain chain;
      try {
        chain = await fetch(Person.fromId(owner));
      } on EcpDeviceChainException {
        results.addAll(ownerLeaves.map((l) => (l, LeafStatus.unverified)));
        continue;
      } on EcpDeviceChainChangedException {
        results.addAll(ownerLeaves.map((l) => (l, LeafStatus.unverified)));
        continue;
      }
      for (final leaf in ownerLeaves) {
        final status = chain.deviceForKey(leaf.signatureKey) != null
            ? LeafStatus.device
            : chain.everListed(leaf.signatureKey)
            ? LeafStatus.revoked
            : LeafStatus.unknown;
        results.add((leaf, status));
      }
    }
    return results;
  }

  /// Signs an entry adding another device of the current user. Submitting it
  /// to the server is up to the caller.
  Future<DeviceChainEntry> approve({
    required String did,
    required Uint8List publicKey,
  }) async {
    final chain = await fetch(core.identity);
    return chain.approve(
      did: did,
      identityKey: publicKey,
      signerDid: activitySender.did,
      credential: await _credential(),
    );
  }

  /// Signs an entry revoking a device of the current user, this one included.
  /// Null when [did] is not in the chain, i.e. it was never approved.
  Future<DeviceChainEntry?> revoke({required String did}) async {
    final chain = await fetch(core.identity);
    if (chain.deviceFor(did) == null) return null;
    return chain.revoke(
      did: did,
      signerDid: activitySender.did,
      credential: await _credential(),
    );
  }

  /// Takes a key package of [device], checking it is signed by the key the
  /// chain lists for the device and names [person] as its identity.
  Future<KeyPackage> requestKey(Person person, Device device) async {
    final response = await activitySender.client.post(device.keyCollection);
    if (response.statusCode != 200) {
      throw EcpNetworkException(
        'Failed to get a key package for device ${device.did}',
        statusCode: response.statusCode,
      );
    }
    final keyPackage = KeyPackage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    final parsed = parseKeyPackage(keyPackage.key);
    if (!bytesEqual(parsed.signatureKey, device.publicKey) ||
        utf8.decode(parsed.identity, allowMalformed: true) !=
            person.id.toString()) {
      throw EcpDeviceChainException(
        'Key package for ${device.did} does not match its device',
      );
    }
    return keyPackage;
  }

  Future<MlsCredentialRecord> _credential() async {
    final credential = await core.storage.mlsCredentialStore.getCredential();
    if (credential == null) {
      throw const EcpException('No MLS credential on this device');
    }
    return credential;
  }

  Future<List<DeviceChainEntry>> _fetchEntries(Person person) async {
    final response = await activitySender.client.get(person.devicesEndpoint);
    if (response.statusCode != 200) {
      throw EcpNetworkException(
        'Failed to get devices for ${person.id}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    final items = decoded is Map<String, dynamic>
        ? decoded['orderedItems'] ?? decoded['items'] ?? []
        : decoded;
    if (items is! List) {
      throw EcpDeviceChainException('Malformed device chain of ${person.id}');
    }
    try {
      return items
          .map((e) => DeviceChainEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on EcpDeviceChainException {
      rethrow;
    } catch (e) {
      throw EcpDeviceChainException(
        'Malformed device chain of ${person.id}',
        cause: e,
      );
    }
  }
}

/// Where a group leaf stands in the device chain of the user it names.
enum LeafStatus {
  /// One of the user's current devices.
  device,

  /// Was one of the user's devices, but has since been revoked or re-keyed.
  revoked,

  /// Never was one of the user's devices.
  unknown,

  /// The user's chain changed and has not been accepted with
  /// [DeviceManager.trust], or is invalid, so the leaf can't be checked.
  unverified,
}
