// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../src/types/encrypted_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptedMessage _$EncryptedMessageFromJson(Map<String, dynamic> json) =>
    EncryptedMessage(
      context: json['@context'],
      typeField: json['type'] as String,
      id: json['id'] == null ? null : Uri.parse(json['id'] as String),
      content: (json['content'] as List<dynamic>)
          .map((e) => EncryptedMessageEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      attributedTo: Uri.parse(json['attributedTo'] as String),
      to: (json['to'] as List<dynamic>)
          .map((e) => Uri.parse(e as String))
          .toList(),
    );

Map<String, dynamic> _$EncryptedMessageToJson(EncryptedMessage instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'type': instance.typeField,
      'content': instance.content.map((e) => e.toJson()).toList(),
      'attributedTo': instance.attributedTo.toString(),
      'to': instance.to.map((e) => e.toString()).toList(),
    };

EncryptedMessageEntry _$EncryptedMessageEntryFromJson(
  Map<String, dynamic> json,
) => EncryptedMessageEntry(
  to: Uri.parse(json['to'] as String),
  from: Uri.parse(json['from'] as String),
  content: EncryptedMessageEntry._de(json['content'] as String),
);

Map<String, dynamic> _$EncryptedMessageEntryToJson(
  EncryptedMessageEntry instance,
) => <String, dynamic>{
  'to': instance.to.toString(),
  'from': instance.from.toString(),
  'content': EncryptedMessageEntry._se(instance.content),
};
