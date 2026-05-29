import 'dart:typed_data';

class MlsGroupRecord {
  final int id;
  final Uint8List groupIdBytes;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final bool isActive;

  const MlsGroupRecord({
    required this.id,
    required this.groupIdBytes,
    required this.createdAt,
    this.displayName,
    this.lastActivityAt,
    this.isActive = true,
  });
}
