// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../src/core/types/encrypted_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EncryptedMessage _$EncryptedMessageFromJson(Map<String, dynamic> json) =>
    EncryptedMessage(
      context: json['@context'],
      typeField: json['type'] as String,
      id: json['id'] == null ? null : Uri.parse(json['id'] as String),
      ciphertext: _$JsonConverterFromJson<String, Uint8List>(
        json['ciphertext'],
        const Uint8ListConverter().fromJson,
      ),
      recipients: (json['recipients'] as List<dynamic>)
          .map((e) => EncryptedRecipient.fromJson(e as Map<String, dynamic>))
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
      'ciphertext': _$JsonConverterToJson<String, Uint8List>(
        instance.ciphertext,
        const Uint8ListConverter().toJson,
      ),
      'recipients': instance.recipients.map((e) => e.toJson()).toList(),
      'attributedTo': instance.attributedTo.toString(),
      'to': instance.to.map((e) => e.toString()).toList(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

EncryptedRecipient _$EncryptedRecipientFromJson(Map<String, dynamic> json) =>
    EncryptedRecipient(
      to: Uri.parse(json['to'] as String),
      from: Uri.parse(json['from'] as String),
      welcome: _$JsonConverterFromJson<String, Uint8List>(
        json['welcome'],
        const Uint8ListConverter().fromJson,
      ),
      commit: _$JsonConverterFromJson<String, Uint8List>(
        json['commit'],
        const Uint8ListConverter().fromJson,
      ),
    );

Map<String, dynamic> _$EncryptedRecipientToJson(EncryptedRecipient instance) =>
    <String, dynamic>{
      'to': instance.to.toString(),
      'from': instance.from.toString(),
      'welcome': _$JsonConverterToJson<String, Uint8List>(
        instance.welcome,
        const Uint8ListConverter().toJson,
      ),
      'commit': _$JsonConverterToJson<String, Uint8List>(
        instance.commit,
        const Uint8ListConverter().toJson,
      ),
    };
