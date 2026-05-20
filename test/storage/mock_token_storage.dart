import 'dart:typed_data';

import 'package:ecp/ecp.dart';

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

class InMemoryMlsEngineConfigStore extends MlsEngineConfigStore {
  final MlsEngineConfig _config;

  InMemoryMlsEngineConfigStore({String? dbPath})
    : _config = MlsEngineConfig(
        dbPath: dbPath ?? ':memory:',
        encryptionKey: Uint8List.fromList(List.filled(32, 1)),
      );

  @override
  Future<MlsEngineConfig> getConfig() async => _config;
}

class InMemoryMlsCredentialStore extends MlsCredentialStore {
  MlsCredentialRecord? _record;

  @override
  Future<MlsCredentialRecord?> getCredential() async => _record;

  @override
  Future<void> saveCredential(MlsCredentialRecord record) async {
    _record = record;
  }
}

class InMemoryMlsKeyPackageStore extends MlsKeyPackageStore {
  List<Uint8List> _keyPackages = [];

  @override
  Future<List<Uint8List>> getKeyPackages() async => _keyPackages;

  @override
  Future<void> saveKeyPackages(List<Uint8List> keyPackages) async {
    _keyPackages = keyPackages;
  }
}

class MockTokenStorage extends Storage {
  MockTokenStorage()
    : super(
        mlsEngineConfigStore: InMemoryMlsEngineConfigStore(),
        mlsCredentialStore: InMemoryMlsCredentialStore(),
        mlsKeyPackageStore: InMemoryMlsKeyPackageStore(),
        userStore: InMemoryUserStore(),
        capabilitiesStore: InMemoryCapabilitiesStore(),
      );

  @override
  Future<void> clear() async {}
}
