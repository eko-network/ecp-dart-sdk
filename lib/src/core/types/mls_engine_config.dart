import 'dart:typed_data';

class MlsEngineConfig {
  final String dbPath;
  final Uint8List encryptionKey;

  const MlsEngineConfig({required this.dbPath, required this.encryptionKey});
}
