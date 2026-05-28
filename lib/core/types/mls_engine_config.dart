import 'dart:math';
import 'dart:typed_data';
import 'package:ecp/core.dart';

class MlsEngineConfig {
  final String dbPath;
  final Uint8List encryptionKey;

  const MlsEngineConfig({required this.dbPath, required this.encryptionKey});

  static Future<MlsEngineConfig> fromPath(String path, Storage storage) async {
    final stored = await storage.mlsEngineConfigStore.getConfig();
    final config;
    if (stored == null) {
      final random = Random.secure();
      final keyBytes = Uint8List.fromList(
        List<int>.generate(32, (index) => random.nextInt(256)),
      );

      config = MlsEngineConfig(dbPath: path, encryptionKey: keyBytes);
      await storage.mlsEngineConfigStore.saveConfig(config);
    } else {
      config = stored;
    }
    return config;
  }
}
