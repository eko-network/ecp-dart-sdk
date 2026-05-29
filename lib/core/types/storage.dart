import 'dart:typed_data';

import 'package:ecp/ecp.dart';

typedef CapabilitiesWithTime = ({
  Map<String, dynamic> capabilities,
  DateTime timestamp,
});

abstract class MlsEngineConfigStore {
  Future<MlsEngineConfig?> getConfig();
  Future<void> saveConfig(MlsEngineConfig config);
}

abstract class MlsCredentialStore {
  Future<MlsCredentialRecord?> getCredential();
  Future<void> saveCredential(MlsCredentialRecord record);
}

abstract class CapabilitiesStore {
  Future<void> saveCapabilities(Map<String, dynamic> capabilities);
  Future<CapabilitiesWithTime?> getCapabilities();
}

abstract class GroupStore {
  Future<void> saveGroup({required Uint8List groupIdBytes, String displayName});
  Future<MlsGroupRecord?> getGroup(int id);
}

abstract class Storage {
  final MlsEngineConfigStore mlsEngineConfigStore;
  final MlsCredentialStore mlsCredentialStore;
  final CapabilitiesStore capabilitiesStore;
  final GroupStore groupStore;
  Storage({
    required this.mlsEngineConfigStore,
    required this.groupStore,
    required this.mlsCredentialStore,
    required this.capabilitiesStore,
  });

  Future<void> clear();
}
