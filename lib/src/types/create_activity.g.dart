// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateActivity _$CreateActivityFromJson(Map<String, dynamic> json) =>
    CreateActivity(
      context: json['@context'],
      typeField: json['type'] as String,
      id: json['id'] == null ? null : Uri.parse(json['id'] as String),
      actor: Uri.parse(json['actor'] as String),
      object: EncryptedMessage.fromJson(json['object'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateActivityToJson(CreateActivity instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'type': instance.typeField,
      'actor': instance.actor.toString(),
      'object': instance.object.toJson(),
    };
