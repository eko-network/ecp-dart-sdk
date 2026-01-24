// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../src/types/person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
  context: json['@context'] ?? '',
  typeField: json['type'] as String? ?? 'Person',
  id: Uri.parse(json['id'] as String),
  inbox: Uri.parse(json['inbox'] as String),
  outbox: Uri.parse(json['outbox'] as String),
  devices: Uri.parse(json['devices'] as String),
  preferredUsername: json['preferredUsername'] as String,
);

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
  '@context': instance.context,
  'type': instance.typeField,
  'id': instance.id.toString(),
  'inbox': instance.inbox.toString(),
  'outbox': instance.outbox.toString(),
  'devices': instance.devices.toString(),
  'preferredUsername': instance.preferredUsername,
};
