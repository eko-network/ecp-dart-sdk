import 'dart:typed_data';

import 'package:ecp/ecp.dart';

typedef CapabilitiesWithTime = ({
  Map<String, dynamic> capabilities,
  DateTime timestamp,
});

/// A decrypted inbox message persisted locally.
///
/// [serverActivityId] is the wire-layer Create activity URL from the server.
/// [id] is the id of the created object, which replies, reactions, edits and
/// deletes refer to.
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

  /// When the content was last replaced by an Update, null if never edited.
  final DateTime? editedAt;

  /// Deleted for everyone by its sender, content and attachments are gone.
  final bool deleted;

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
    this.editedAt,
    this.deleted = false,
  });
}

/// An emoji reaction of [senderId] to message [messageId]. Each sender has at
/// most one reaction per message.
class StoredReaction {
  /// The EmojiReact object's id, a Delete of it removes the reaction.
  final InternalId id;
  final InternalId messageId;
  final Uint8List groupId;
  final Uri senderId;
  final String emoji;
  final DateTime receivedAt;

  const StoredReaction({
    required this.id,
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.emoji,
    required this.receivedAt,
  });
}

/// How far [reader] has read [groupId]: every message up to and including
/// [messageId]. Messages are ordered by when this device received them, so
/// the cursor covers those received at or before [position].
class ReadCursor {
  final Uint8List groupId;
  final Uri reader;
  final InternalId messageId;

  /// When this device received message [messageId].
  final DateTime position;

  const ReadCursor({
    required this.groupId,
    required this.reader,
    required this.messageId,
    required this.position,
  });

  bool covers(StoredMessage message) => !message.receivedAt.isAfter(position);
}

/// Something received that the user may be notified about, or that changes
/// what they were notified about.
sealed class ReceivedEvent {
  const ReceivedEvent();
}

class ReceivedMessage extends ReceivedEvent {
  final StoredMessage message;
  const ReceivedMessage(this.message);
}

class ReceivedReaction extends ReceivedEvent {
  final StoredReaction reaction;

  /// The message reacted to.
  final StoredMessage message;
  const ReceivedReaction(this.reaction, this.message);
}

/// A read cursor moved, e.g. our own when another of our devices read a chat.
class ReceivedRead extends ReceivedEvent {
  final ReadCursor cursor;
  const ReceivedRead(this.cursor);
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

  /// Deletes group [from] and records that [into] took over from it, see
  /// [GroupManager.mergeDms]. Groups that were merged into [from] now point
  /// to [into].
  Future<void> mergeGroup({required Uint8List from, required Uint8List into});

  /// The group that took over from [groupIdBytes], null when none did.
  Future<Uint8List?> getMergedInto(Uint8List groupIdBytes);
}

abstract class ProcessedObjectStore {
  Future<void> add(Uri id);
  Future<bool> check(Uri id);
  Future<bool> markDelivered(Uri id);
}

abstract class MessageStore {
  Future<void> saveMessage(StoredMessage message);
  Future<bool> hasMessage(Uri serverActivityId);

  /// The message in [groupId] whose object id is [id].
  Future<StoredMessage?> getMessage(Uint8List groupId, InternalId id);
  Future<bool> markMessageDelivered(Uri serverActivityId);

  /// Replaces the content of message [id], keeping the previous content as a
  /// revision of its edit history.
  Future<void> editMessage(
    Uint8List groupId,
    InternalId id, {
    required String? content,
    required DateTime editedAt,
  });

  /// Deletes message [id] for everyone: its content, attachments, edit
  /// history and reactions are removed and it stays as a tombstone.
  Future<void> deleteMessage(Uint8List groupId, InternalId id);

  /// Saves [reaction], replacing its sender's earlier reaction to the same
  /// message.
  Future<void> saveReaction(StoredReaction reaction);

  /// The reaction in [groupId] whose EmojiReact object id is [id].
  Future<StoredReaction?> getReaction(Uint8List groupId, InternalId id);
  Future<void> deleteReaction(Uint8List groupId, InternalId id);

  /// How far [reader] has read [groupId], null if they read nothing yet.
  Future<ReadCursor?> getReadCursor(Uint8List groupId, Uri reader);

  /// Moves [reader]'s cursor in [groupId] to message [messageId] when it was
  /// received after the message the cursor is at. Returns the moved cursor,
  /// null when it did not move or this device doesn't have the message.
  Future<ReadCursor?> advanceReadCursor(
    Uint8List groupId,
    Uri reader,
    InternalId messageId,
  );

  /// Moves the messages, reactions and read cursors of group [from] to group
  /// [to], when a chat replaces another one. Of two cursors of the same
  /// reader the later one is kept.
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
