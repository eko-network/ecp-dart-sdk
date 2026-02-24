import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'activities.dart';
import 'key_bundle.dart' show Uint8ListConverter;
import 'objects.dart' show UuidConverter;

part '../../generated/src/types/group.g.dart';

/// Local plaintext group state maintained by the client.
@JsonSerializable()
class GroupState {
  @UuidConverter()
  final UuidValue groupId;
  final int epoch;
  final List<Uri> members;
  final List<Uri> admins;

  @Uint8ListConverter()
  final Uint8List groupMasterKey;

  GroupState({
    required this.groupId,
    required this.epoch,
    required this.members,
    required this.admins,
    required this.groupMasterKey,
  });

  factory GroupState.fromJson(Map<String, dynamic> json) =>
      _$GroupStateFromJson(json);

  Map<String, dynamic> toJson() => _$GroupStateToJson(this);

  GroupState copyWith({
    int? epoch,
    List<Uri>? members,
    List<Uri>? admins,
    Uint8List? groupMasterKey,
  }) {
    return GroupState(
      groupId: groupId,
      epoch: epoch ?? this.epoch,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      groupMasterKey: groupMasterKey ?? this.groupMasterKey,
    );
  }
}

/// Encrypted group state blob stored on the server.
///
/// The server treats this as opaque, so it cannot inspect or modify
/// the contents. Used for device synchronization and recovery.
@JsonSerializable()
class EncryptedGroupState {
  final String groupId;
  final int epoch;
  final String content; // base64-encoded encrypted ciphertext

  EncryptedGroupState({
    required this.groupId,
    required this.epoch,
    required this.content,
  });

  factory EncryptedGroupState.fromJson(Map<String, dynamic> json) =>
      _$EncryptedGroupStateFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptedGroupStateToJson(this);
}

/// Signature field for group control messages.
///
/// Contains the HMAC-SHA256 computed over the canonical JSON
/// of the control message (with the signature field stripped).
@JsonSerializable()
class GroupSignature {
  final String alg;
  final String value; // base64-encoded HMAC

  GroupSignature({this.alg = 'HMAC-SHA256', required this.value});

  factory GroupSignature.fromJson(Map<String, dynamic> json) =>
      _$GroupSignatureFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSignatureToJson(this);
}

/// The following Group Control Activities are sent inside encrypted 
/// SignalEnvelopes via sendMessage. They implement StableActivity to 
/// use the existing message pipeline.

/// Sent to all initial members (and to new members being added).
/// Contains the full group state including the master key.
class GroupCreate implements StableActivity {
  @override
  final ActivityBase base;
  final UuidValue groupId;
  final int epoch;
  final List<Uri> members;
  final List<Uri> admins;
  final String groupMasterKey; // base64-encoded
  final GroupSignature? signature;

  GroupCreate({
    required this.base,
    required this.groupId,
    required this.epoch,
    required this.members,
    required this.admins,
    required this.groupMasterKey,
    this.signature,
  });

  @override
  String get type => 'GroupCreate';

  factory GroupCreate.fromJson(Map<String, dynamic> json) {
    return GroupCreate(
      base: ActivityBase.fromJson(json),
      groupId: UuidValue.fromString(json['groupId'] as String),
      epoch: json['epoch'] as int,
      members: (json['members'] as List)
          .map((e) => Uri.parse(e as String))
          .toList(),
      admins: (json['admins'] as List)
          .map((e) => Uri.parse(e as String))
          .toList(),
      groupMasterKey: json['groupMasterKey'] as String,
      signature: json['signature'] != null
          ? GroupSignature.fromJson(json['signature'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['groupId'] = groupId.toString();
    json['epoch'] = epoch;
    json['members'] = members.map((e) => e.toString()).toList();
    json['admins'] = admins.map((e) => e.toString()).toList();
    json['groupMasterKey'] = groupMasterKey;
    if (signature != null) {
      json['signature'] = signature!.toJson();
    }
    return json;
  }
}

/// Sent to existing members when new members are added.
/// Contains the new rotated master key.
class GroupMemberAdd implements StableActivity {
  @override
  final ActivityBase base;
  final UuidValue groupId;
  final int epoch;
  final List<Uri> added;
  final String groupMasterKey; // base64-encoded (rotated)
  final GroupSignature? signature;

  GroupMemberAdd({
    required this.base,
    required this.groupId,
    required this.epoch,
    required this.added,
    required this.groupMasterKey,
    this.signature,
  });

  @override
  String get type => 'GroupMemberAdd';

  factory GroupMemberAdd.fromJson(Map<String, dynamic> json) {
    return GroupMemberAdd(
      base: ActivityBase.fromJson(json),
      groupId: UuidValue.fromString(json['groupId'] as String),
      epoch: json['epoch'] as int,
      added: (json['added'] as List)
          .map((e) => Uri.parse(e as String))
          .toList(),
      groupMasterKey: json['groupMasterKey'] as String,
      signature: json['signature'] != null
          ? GroupSignature.fromJson(json['signature'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['groupId'] = groupId.toString();
    json['epoch'] = epoch;
    json['added'] = added.map((e) => e.toString()).toList();
    json['groupMasterKey'] = groupMasterKey;
    if (signature != null) {
      json['signature'] = signature!.toJson();
    }
    return json;
  }
}

/// Sent to remaining members when members are removed.
/// Contains the new rotated master key.
class GroupMemberRemove implements StableActivity {
  @override
  final ActivityBase base;
  final UuidValue groupId;
  final int epoch;
  final List<Uri> removed;
  final String groupMasterKey; // base64-encoded rotated key
  final GroupSignature? signature;

  GroupMemberRemove({
    required this.base,
    required this.groupId,
    required this.epoch,
    required this.removed,
    required this.groupMasterKey,
    this.signature,
  });

  @override
  String get type => 'GroupMemberRemove';

  factory GroupMemberRemove.fromJson(Map<String, dynamic> json) {
    return GroupMemberRemove(
      base: ActivityBase.fromJson(json),
      groupId: UuidValue.fromString(json['groupId'] as String),
      epoch: json['epoch'] as int,
      removed: (json['removed'] as List)
          .map((e) => Uri.parse(e as String))
          .toList(),
      groupMasterKey: json['groupMasterKey'] as String,
      signature: json['signature'] != null
          ? GroupSignature.fromJson(json['signature'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['groupId'] = groupId.toString();
    json['epoch'] = epoch;
    json['removed'] = removed.map((e) => e.toString()).toList();
    json['groupMasterKey'] = groupMasterKey;
    if (signature != null) {
      json['signature'] = signature!.toJson();
    }
    return json;
  }
}

/// Key rotation without membership change.
/// Contains the new rotated master key.
class GroupKeyRotate implements StableActivity {
  @override
  final ActivityBase base;
  final UuidValue groupId;
  final int epoch;
  final String groupMasterKey; // base64-encoded rotated key
  final GroupSignature? signature;

  GroupKeyRotate({
    required this.base,
    required this.groupId,
    required this.epoch,
    required this.groupMasterKey,
    this.signature,
  });

  @override
  String get type => 'GroupKeyRotate';

  factory GroupKeyRotate.fromJson(Map<String, dynamic> json) {
    return GroupKeyRotate(
      base: ActivityBase.fromJson(json),
      groupId: UuidValue.fromString(json['groupId'] as String),
      epoch: json['epoch'] as int,
      groupMasterKey: json['groupMasterKey'] as String,
      signature: json['signature'] != null
          ? GroupSignature.fromJson(json['signature'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['groupId'] = groupId.toString();
    json['epoch'] = epoch;
    json['groupMasterKey'] = groupMasterKey;
    if (signature != null) {
      json['signature'] = signature!.toJson();
    }
    return json;
  }
}
