// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../core/types/activitypub/activities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Typing _$TypingFromJson(Map<String, dynamic> json) =>
    Typing($type: json['type'] as String?);

Map<String, dynamic> _$TypingToJson(Typing instance) => <String, dynamic>{
  'type': instance.$type,
};

Create _$CreateFromJson(Map<String, dynamic> json) => Create(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  object: ActivityPubObject.fromJson(json['object'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$CreateToJson(Create instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'object': instance.object,
  'type': instance.$type,
};

Update _$UpdateFromJson(Map<String, dynamic> json) => Update(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  object: ActivityPubObject.fromJson(json['object'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$UpdateToJson(Update instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'object': instance.object,
  'type': instance.$type,
};

Delete _$DeleteFromJson(Map<String, dynamic> json) => Delete(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  object: json['object'],
  $type: json['type'] as String?,
);

Map<String, dynamic> _$DeleteToJson(Delete instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'object': instance.object,
  'type': instance.$type,
};

Delivered _$DeliveredFromJson(Map<String, dynamic> json) => Delivered(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  object: const UriConverter().fromJson(json['object'] as String),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$DeliveredToJson(Delivered instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'object': const UriConverter().toJson(instance.object),
  'type': instance.$type,
};
