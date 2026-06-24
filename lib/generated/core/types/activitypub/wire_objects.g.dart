// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../core/types/activitypub/wire_objects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalRequest _$ApprovalRequestFromJson(Map<String, dynamic> json) =>
    ApprovalRequest(
      context: json['@context'] ?? ecpJsonLdContext,
      id: _$JsonConverterFromJson<String, Uri>(
        json['id'],
        const UriConverter().fromJson,
      ),
      actor: const UriConverter().fromJson(json['actor'] as String),
      to: (json['to'] as List<dynamic>)
          .map((e) => const UriConverter().fromJson(e as String))
          .toList(),
      publicKey: const Uint8ListConverter().fromJson(
        json['publicKey'] as String,
      ),
      did: json['did'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ApprovalRequestToJson(ApprovalRequest instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'id': _$JsonConverterToJson<String, Uri>(
        instance.id,
        const UriConverter().toJson,
      ),
      'actor': const UriConverter().toJson(instance.actor),
      'to': instance.to.map(const UriConverter().toJson).toList(),
      'publicKey': const Uint8ListConverter().toJson(instance.publicKey),
      'did': instance.did,
      'type': instance.$type,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

PrivateMessage _$PrivateMessageFromJson(Map<String, dynamic> json) =>
    PrivateMessage(
      context: json['@context'] ?? ecpJsonLdContext,
      id: _$JsonConverterFromJson<String, Uri>(
        json['id'],
        const UriConverter().fromJson,
      ),
      actor: const UriConverter().fromJson(json['actor'] as String),
      to: (json['to'] as List<dynamic>)
          .map((e) => const UriConverter().fromJson(e as String))
          .toList(),
      content: const Uint8ListConverter().fromJson(json['content'] as String),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$PrivateMessageToJson(PrivateMessage instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'id': _$JsonConverterToJson<String, Uri>(
        instance.id,
        const UriConverter().toJson,
      ),
      'actor': const UriConverter().toJson(instance.actor),
      'to': instance.to.map(const UriConverter().toJson).toList(),
      'content': const Uint8ListConverter().toJson(instance.content),
      'type': instance.$type,
    };

WelcomeMessage _$WelcomeMessageFromJson(Map<String, dynamic> json) =>
    WelcomeMessage(
      context: json['@context'] ?? ecpJsonLdContext,
      id: _$JsonConverterFromJson<String, Uri>(
        json['id'],
        const UriConverter().fromJson,
      ),
      actor: const UriConverter().fromJson(json['actor'] as String),
      to: (json['to'] as List<dynamic>)
          .map((e) => const UriConverter().fromJson(e as String))
          .toList(),
      content: const Uint8ListConverter().fromJson(json['content'] as String),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WelcomeMessageToJson(WelcomeMessage instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'id': _$JsonConverterToJson<String, Uri>(
        instance.id,
        const UriConverter().toJson,
      ),
      'actor': const UriConverter().toJson(instance.actor),
      'to': instance.to.map(const UriConverter().toJson).toList(),
      'content': const Uint8ListConverter().toJson(instance.content),
      'type': instance.$type,
    };
