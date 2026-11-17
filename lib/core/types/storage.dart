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
  final List<ActivityPubObject> attachment;
  final DateTime receivedAt;
  final bool delivered;

  const StoredMessage({
    required this.serverActivityId,
    required this.receivedAt,
    required this.senderId,
    required this.id,
    this.content,
    this.inReplyTo,
    required this.attachment,
    required this.groupId,
    this.delivered = false,
  });
}

class StoredApprovalRequest {
  final String did;
  final Uint8List publicKey;
  const StoredApprovalRequest({required this.did, required this.publicKey});
}

abstract class MlsEngineConfigStore {
  Future<MlsEngineConfig?> getConfig();
  Future<void> saveConfig(MlsEngineConfig config);
  Future<void> clearConfig();
}

abstract class MlsCredentialStore {
  Future<MlsCredentialRecord?> getCredential();
  Future<void> saveCredential(MlsCredentialRecord record);
}

abstract class CapabilitiesStore {
  Future<void> saveCapabilities(Map<String, dynamic> capabilities);
  Future<CapabilitiesWithTime?> getCapabilities();
}

/// Groups are active (shown) or hidden. A group joined with leaves of a user
/// whose device chain changed stays hidden until the change is accepted, see
/// [GroupManager.acceptDeviceReset].
abstract class GroupStore {
  Future<void> saveGroup({
    required Uint8List groupIdBytes,
    String displayName,
    bool isActive = true,
  });
  Future<void> setGroupActive(Uint8List groupIdBytes, bool isActive);
  Future<void> deleteGroup(Uint8List groupIdBytes);
  Future<MlsGroupRecord?> getGroup(int id);
  Future<MlsGroupRecord?> getGroupByGroupId(Uint8List groupIdBytes);
  Future<List<MlsGroupRecord>> getActiveGroups();
  Future<List<MlsGroupRecord>> getHiddenGroups();
}

abstract class ProcessedObjectStore {
  Future<void> add(Uri id);
  Future<bool> check(Uri id);
  Future<bool> markDelivered(Uri id);
}

abstract class MessageStore {
  Future<void> saveMessage(StoredMessage message);
  Future<bool> markMessageDelivered(Uri serverActivityId);

  /// Moves the messages of group [from] to group [to], when a chat replaces
  /// another one.
  Future<void> moveMessages({required Uint8List from, required Uint8List to});
}

abstract class ApprovalRequestStore {
  Future<void> saveApprovalRequest(StoredApprovalRequest request);
}

/// The head of each user's device chain this device last verified, so a
/// chain that was swapped or rolled back is noticed.
abstract class DeviceChainStore {
  Future<Uint8List?> getPinnedHead(Uri actor);
  Future<void> pinHead(Uri actor, Uint8List head);
}

abstract class Storage {
  final MlsEngineConfigStore mlsEngineConfigStore;
  final MlsCredentialStore mlsCredentialStore;
  final CapabilitiesStore capabilitiesStore;
  final GroupStore groupStore;
  final MessageStore messageStore;
  final ProcessedObjectStore processedObjectStore;
  final ApprovalRequestStore approvalRequestStore;
  final DeviceChainStore deviceChainStore;
  Storage({
    required this.mlsEngineConfigStore,
    required this.groupStore,
    required this.mlsCredentialStore,
    required this.capabilitiesStore,
    required this.messageStore,
    required this.processedObjectStore,
    required this.approvalRequestStore,
    required this.deviceChainStore,
  });

  Future<void> clear();
}
