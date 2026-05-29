// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../core/types/activitypub/objects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, InternalId>(
    json['inReplyTo'],
    const InternalIdConverter().fromJson,
  ),
  content: json['content'] as String?,
  attachments: (json['attachments'] as List<dynamic>?)
      ?.map((e) => ActivityPubObject.fromJson(e as Map<String, dynamic>))
      .toList(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'inReplyTo': _$JsonConverterToJson<String, InternalId>(
    instance.inReplyTo,
    const InternalIdConverter().toJson,
  ),
  'content': instance.content,
  'attachments': instance.attachments,
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

EmojiReact _$EmojiReactFromJson(Map<String, dynamic> json) => EmojiReact(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, InternalId>(
    json['inReplyTo'],
    const InternalIdConverter().fromJson,
  ),
  content: json['content'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$EmojiReactToJson(EmojiReact instance) =>
    <String, dynamic>{
      'id': const InternalIdConverter().toJson(instance.id),
      'inReplyTo': _$JsonConverterToJson<String, InternalId>(
        instance.inReplyTo,
        const InternalIdConverter().toJson,
      ),
      'content': instance.content,
      'type': instance.$type,
    };

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, InternalId>(
    json['inReplyTo'],
    const InternalIdConverter().fromJson,
  ),
  url: const UriConverter().fromJson(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
  width: (json['width'] as num?)?.toInt(),
  name: json['name'] as String?,
  height: (json['height'] as num?)?.toInt(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'inReplyTo': _$JsonConverterToJson<String, InternalId>(
    instance.inReplyTo,
    const InternalIdConverter().toJson,
  ),
  'url': const UriConverter().toJson(instance.url),
  'encryption': instance.encryption,
  'key': instance.key,
  'mediaType': instance.mediaType,
  'width': instance.width,
  'name': instance.name,
  'height': instance.height,
  'type': instance.$type,
};

Image _$ImageFromJson(Map<String, dynamic> json) => Image(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, InternalId>(
    json['inReplyTo'],
    const InternalIdConverter().fromJson,
  ),
  url: const UriConverter().fromJson(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
  width: (json['width'] as num?)?.toInt(),
  name: json['name'] as String?,
  height: (json['height'] as num?)?.toInt(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'inReplyTo': _$JsonConverterToJson<String, InternalId>(
    instance.inReplyTo,
    const InternalIdConverter().toJson,
  ),
  'url': const UriConverter().toJson(instance.url),
  'encryption': instance.encryption,
  'key': instance.key,
  'mediaType': instance.mediaType,
  'width': instance.width,
  'name': instance.name,
  'height': instance.height,
  'type': instance.$type,
};

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, InternalId>(
    json['inReplyTo'],
    const InternalIdConverter().fromJson,
  ),
  url: const UriConverter().fromJson(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'inReplyTo': _$JsonConverterToJson<String, InternalId>(
    instance.inReplyTo,
    const InternalIdConverter().toJson,
  ),
  'url': const UriConverter().toJson(instance.url),
  'encryption': instance.encryption,
  'key': instance.key,
  'mediaType': instance.mediaType,
  'type': instance.$type,
};

Audio _$AudioFromJson(Map<String, dynamic> json) => Audio(
  id: const InternalIdConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, InternalId>(
    json['inReplyTo'],
    const InternalIdConverter().fromJson,
  ),
  url: const UriConverter().fromJson(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$AudioToJson(Audio instance) => <String, dynamic>{
  'id': const InternalIdConverter().toJson(instance.id),
  'inReplyTo': _$JsonConverterToJson<String, InternalId>(
    instance.inReplyTo,
    const InternalIdConverter().toJson,
  ),
  'url': const UriConverter().toJson(instance.url),
  'encryption': instance.encryption,
  'key': instance.key,
  'mediaType': instance.mediaType,
  'type': instance.$type,
};
