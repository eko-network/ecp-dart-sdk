import 'dart:typed_data';
import 'mls_credential_record.dart';
import 'mls_engine_config.dart';

typedef CapabilitiesWithTime = ({
  Map<String, dynamic> capabilities,
  DateTime timestamp,
});

abstract class MlsEngineConfigStore {
  Future<MlsEngineConfig> getConfig();
}

abstract class MlsCredentialStore {
  Future<MlsCredentialRecord?> getCredential();
  Future<void> saveCredential(MlsCredentialRecord record);
}

abstract class MlsKeyPackageStore {
  Future<List<Uint8List>> getKeyPackages();
  Future<void> saveKeyPackages(List<Uint8List> keyPackages);
}

abstract class UserStore {
  Future<int> saveDevice(Uri id, Uri did);
  Future<int?> getDevice(Uri did);
  Future<int?> removeDevice(Uri did);
  Future<Map<Uri, int>?> getUser(Uri id);
}

abstract class CapabilitiesStore {
  Future<void> saveCapabilities(Map<String, dynamic> capabilities);
  Future<CapabilitiesWithTime?> getCapabilities();
}

abstract class Storage {
  final MlsEngineConfigStore mlsEngineConfigStore;
  final MlsCredentialStore mlsCredentialStore;
  final MlsKeyPackageStore mlsKeyPackageStore;
  final UserStore userStore;
  final CapabilitiesStore capabilitiesStore;
  Storage({
    required this.mlsEngineConfigStore,
    required this.mlsCredentialStore,
    required this.mlsKeyPackageStore,
    required this.userStore,
    required this.capabilitiesStore,
  });

  Future<void> clear();
}
