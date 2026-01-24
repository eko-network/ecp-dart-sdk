import 'package:ecp/ecp.dart';
import 'package:collection/collection.dart';

import 'mock_capability_storage.dart';

class InMemoryUserStore extends UserStore {
  final Map<Uri, Map<Uri, int>> _sto = {};
  final Map<Uri, int> _devices = {};
  int _serial = 1;

  @override
  Future<Map<Uri, int>?> getUser(Uri id) async {
    return _sto[id];
  }

  @override
  Future<int> saveDevice(Uri id, Uri did) async {
    final deviceId = _serial++;
    _sto.putIfAbsent(id, () => <Uri, int>{});
    _sto[id]![did] = deviceId;
    _devices[did] = deviceId;
    return deviceId;
  }

  @override
  Future<int?> getDevice(Uri did) async {
    return _devices[did];
  }

  @override
  Future<int?> removeDevice(Uri did) async {
    final deviceId = _devices.remove(did);
    if (deviceId != null) {
      _sto.forEach((userId, devices) {
        devices.remove(did);
      });
      return deviceId;
    }
    return null;
  }
}

class ModifiedInMemoryIdentityKeyStore extends IdentityKeyStore {
  final trustedKeys = Map<SignalProtocolAddress, IdentityKey>();

  IdentityKeyPair? identityKeyPair = null;
  int? localRegistrationId = null;

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async =>
      trustedKeys[address]!;

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async => identityKeyPair!;

  @override
  Future<int> getLocalRegistrationId() async => localRegistrationId!;

  @override
  Future<bool> isTrustedIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
    Direction? direction,
  ) async {
    final trusted = trustedKeys[address];
    if (identityKey == null) {
      return false;
    }
    return trusted == null ||
        ListEquality().equals(trusted.serialize(), identityKey.serialize());
  }

  @override
  Future<bool> saveIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
  ) async {
    final existing = trustedKeys[address];
    if (identityKey == null) {
      return false;
    }
    if (identityKey != existing) {
      trustedKeys[address] = identityKey;
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<IdentityKeyPair?> getIdentityKeyPairOrNull() async {
    return identityKeyPair;
  }

  @override
  Future<void> storeIdentityKeyPair(
    IdentityKeyPair identityKeyPair,
    int localRegistrationId,
  ) async {
    this.identityKeyPair = identityKeyPair;
    this.localRegistrationId = localRegistrationId;
  }
}

class MockTokenStorage extends Storage {
  MockTokenStorage()
    : super(
        preKeyStore: InMemoryPreKeyStore(),
        sessionStore: InMemorySessionStore(),
        signedPreKeyStore: InMemorySignedPreKeyStore(),
        identityKeyStore: ModifiedInMemoryIdentityKeyStore(),
        userStore: InMemoryUserStore(),
        capabilitiesStore: InMemoryCapabilitiesStore(),
      );

  @override
  Future<void> clear() async {}
}
