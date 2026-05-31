import 'dart:typed_data';

import 'package:ecp/ecp.dart';

typedef CapabilitiesWithTime = ({
  Map<String, dynamic> capabilities,
  DateTime timestamp,
});

/// A decrypted inbox message persisted locally.
///
/// [serverActivityId] is the wire-layer Create activity URL from the server.
/// [activity] is the MLS application payload (domain types with [InternalId]).
class StoredMessage {
  final Uri serverActivityId;
  final Uri senderId;
  final InternalId id;
  final Uint8List groupId;
  final String? content;
  final InternalId? inReplyTo;
  final List<InternalId> attachment;
  final DateTime receivedAt;

  const StoredMessage({
    required this.serverActivityId,
    required this.receivedAt,
    required this.senderId,
    required this.id,
    this.content,
    this.inReplyTo,
    required this.attachment,
    required this.groupId,
  });
}

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

abstract class ProcessedObjectStore {
  Future<void> add(Uri id);
  Future<bool> check(Uri id);
}

abstract class MessageStore {
  Future<void> saveMessage(StoredMessage message);
}

abstract class Storage {
  final MlsEngineConfigStore mlsEngineConfigStore;
  final MlsCredentialStore mlsCredentialStore;
  final CapabilitiesStore capabilitiesStore;
  final GroupStore groupStore;
  final MessageStore messageStore;
  final ProcessedObjectStore processedObjectStore;
  Storage({
    required this.mlsEngineConfigStore,
    required this.groupStore,
    required this.mlsCredentialStore,
    required this.capabilitiesStore,
    required this.messageStore,
    required this.processedObjectStore,
  });

  Future<void> clear();
}
