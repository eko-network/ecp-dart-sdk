// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../src/types/group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupState _$GroupStateFromJson(Map<String, dynamic> json) => GroupState(
  groupId: const UuidConverter().fromJson(json['groupId'] as String),
  epoch: (json['epoch'] as num).toInt(),
  members: (json['members'] as List<dynamic>)
      .map((e) => Uri.parse(e as String))
      .toList(),
  admins: (json['admins'] as List<dynamic>)
      .map((e) => Uri.parse(e as String))
      .toList(),
  groupMasterKey: const Uint8ListConverter().fromJson(
    json['groupMasterKey'] as String,
  ),
);

Map<String, dynamic> _$GroupStateToJson(
  GroupState instance,
) => <String, dynamic>{
  'groupId': const UuidConverter().toJson(instance.groupId),
  'epoch': instance.epoch,
  'members': instance.members.map((e) => e.toString()).toList(),
  'admins': instance.admins.map((e) => e.toString()).toList(),
  'groupMasterKey': const Uint8ListConverter().toJson(instance.groupMasterKey),
};

EncryptedGroupState _$EncryptedGroupStateFromJson(Map<String, dynamic> json) =>
    EncryptedGroupState(
      groupId: json['groupId'] as String,
      epoch: (json['epoch'] as num).toInt(),
      content: json['content'] as String,
    );

Map<String, dynamic> _$EncryptedGroupStateToJson(
  EncryptedGroupState instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'epoch': instance.epoch,
  'content': instance.content,
};

GroupSignature _$GroupSignatureFromJson(Map<String, dynamic> json) =>
    GroupSignature(
      alg: json['alg'] as String? ?? 'HMAC-SHA256',
      value: json['value'] as String,
    );

Map<String, dynamic> _$GroupSignatureToJson(GroupSignature instance) =>
    <String, dynamic>{'alg': instance.alg, 'value': instance.value};
