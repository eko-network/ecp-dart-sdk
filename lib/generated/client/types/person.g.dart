// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../client/types/person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
  context: json['@context'] ?? '',
  type: json['type'] as String? ?? 'Person',
  id: Uri.parse(json['id'] as String),
  inbox: Uri.parse(json['inbox'] as String),
  outbox: Uri.parse(json['outbox'] as String),
  devicesEndpoint: Uri.parse(json['devicesEndpoint'] as String),
);

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
  '@context': instance.context,
  'type': instance.type,
  'id': instance.id.toString(),
  'inbox': instance.inbox.toString(),
  'outbox': instance.outbox.toString(),
  'devicesEndpoint': instance.devicesEndpoint.toString(),
};
