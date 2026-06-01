// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../core/types/activitypub/wire_activities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WireTake _$WireTakeFromJson(Map<String, dynamic> json) => WireTake(
  context: json['@context'] ?? ecpJsonLdContext,
  id: _$JsonConverterFromJson<String, Uri>(
    json['id'],
    const UriConverter().fromJson,
  ),
  to: (json['to'] as List<dynamic>)
      .map((e) => const UriConverter().fromJson(e as String))
      .toList(),
  actor: const UriConverter().fromJson(json['actor'] as String),
  result: _$JsonConverterFromJson<Map<String, dynamic>, KeyPackage>(
    json['result'],
    const KeyPackageConvertor().fromJson,
  ),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WireTakeToJson(WireTake instance) => <String, dynamic>{
  '@context': instance.context,
  'id': _$JsonConverterToJson<String, Uri>(
    instance.id,
    const UriConverter().toJson,
  ),
  'to': instance.to.map(const UriConverter().toJson).toList(),
  'actor': const UriConverter().toJson(instance.actor),
  'result': _$JsonConverterToJson<Map<String, dynamic>, KeyPackage>(
    instance.result,
    const KeyPackageConvertor().toJson,
  ),
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

WireCreate _$WireCreateFromJson(Map<String, dynamic> json) => WireCreate(
  context: json['@context'] ?? ecpJsonLdContext,
  id: _$JsonConverterFromJson<String, Uri>(
    json['id'],
    const UriConverter().fromJson,
  ),
  to: (json['to'] as List<dynamic>)
      .map((e) => const UriConverter().fromJson(e as String))
      .toList(),
  object: WireObject.fromJson(json['object'] as Map<String, dynamic>),
  actor: const UriConverter().fromJson(json['actor'] as String),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WireCreateToJson(WireCreate instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'id': _$JsonConverterToJson<String, Uri>(
        instance.id,
        const UriConverter().toJson,
      ),
      'to': instance.to.map(const UriConverter().toJson).toList(),
      'object': instance.object,
      'actor': const UriConverter().toJson(instance.actor),
      'type': instance.$type,
    };

WireDelivered _$WireDeliveredFromJson(Map<String, dynamic> json) =>
    WireDelivered(
      context: json['@context'] ?? ecpJsonLdContext,
      id: _$JsonConverterFromJson<String, Uri>(
        json['id'],
        const UriConverter().fromJson,
      ),
      to: (json['to'] as List<dynamic>)
          .map((e) => const UriConverter().fromJson(e as String))
          .toList(),
      object: const UriConverter().fromJson(json['object'] as String),
      actor: const UriConverter().fromJson(json['actor'] as String),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WireDeliveredToJson(WireDelivered instance) =>
    <String, dynamic>{
      '@context': instance.context,
      'id': _$JsonConverterToJson<String, Uri>(
        instance.id,
        const UriConverter().toJson,
      ),
      'to': instance.to.map(const UriConverter().toJson).toList(),
      'object': const UriConverter().toJson(instance.object),
      'actor': const UriConverter().toJson(instance.actor),
      'type': instance.$type,
    };
