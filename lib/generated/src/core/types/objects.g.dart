// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../src/core/types/objects.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ObjectBase _$ObjectBaseFromJson(Map<String, dynamic> json) => ObjectBase(
  id: const UuidConverter().fromJson(json['id'] as String),
  inReplyTo: _$JsonConverterFromJson<String, UuidValue>(
    json['inReplyTo'],
    const UuidConverter().fromJson,
  ),
);

Map<String, dynamic> _$ObjectBaseToJson(ObjectBase instance) =>
    <String, dynamic>{
      'id': const UuidConverter().toJson(instance.id),
      'inReplyTo': ?_$JsonConverterToJson<String, UuidValue>(
        instance.inReplyTo,
        const UuidConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
  content: json['content'] as String?,
  base: ObjectBase.fromJson(_readBase(json, 'base') as Map<String, dynamic>),
  attachments: (json['attachments'] as List<dynamic>?)
      ?.map((e) => ActivityPubObject.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
  'content': ?instance.content,
  'attachments': ?instance.attachments?.map((e) => e.toJson()).toList(),
};

EmojiReact _$EmojiReactFromJson(Map<String, dynamic> json) => EmojiReact(
  base: ObjectBase.fromJson(_readBase(json, 'base') as Map<String, dynamic>),
  content: json['content'] as String,
);

Map<String, dynamic> _$EmojiReactToJson(EmojiReact instance) =>
    <String, dynamic>{'content': instance.content};

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
  base: ObjectBase.fromJson(_readBase(json, 'base') as Map<String, dynamic>),
  url: Uri.parse(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
  name: json['name'] as String?,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
);

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
  'url': instance.url.toString(),
  'encryption': ?instance.encryption,
  'key': ?instance.key,
  'mediaType': ?instance.mediaType,
  'width': ?instance.width,
  'name': ?instance.name,
  'height': ?instance.height,
};

Image _$ImageFromJson(Map<String, dynamic> json) => Image(
  base: ObjectBase.fromJson(_readBase(json, 'base') as Map<String, dynamic>),
  url: Uri.parse(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  width: (json['width'] as num?)?.toInt(),
  name: json['name'] as String?,
  height: (json['height'] as num?)?.toInt(),
  mediaType: json['mediaType'] as String?,
);

Map<String, dynamic> _$ImageToJson(Image instance) => <String, dynamic>{
  'url': instance.url.toString(),
  'encryption': ?instance.encryption,
  'key': ?instance.key,
  'mediaType': ?instance.mediaType,
  'width': ?instance.width,
  'name': ?instance.name,
  'height': ?instance.height,
};

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
  base: ObjectBase.fromJson(_readBase(json, 'base') as Map<String, dynamic>),
  url: Uri.parse(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
);

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
  'url': instance.url.toString(),
  'encryption': ?instance.encryption,
  'key': ?instance.key,
  'mediaType': ?instance.mediaType,
};

Audio _$AudioFromJson(Map<String, dynamic> json) => Audio(
  base: ObjectBase.fromJson(_readBase(json, 'base') as Map<String, dynamic>),
  url: Uri.parse(json['url'] as String),
  encryption: json['encryption'] as String?,
  key: json['key'] as String?,
  mediaType: json['mediaType'] as String?,
);

Map<String, dynamic> _$AudioToJson(Audio instance) => <String, dynamic>{
  'url': instance.url.toString(),
  'encryption': ?instance.encryption,
  'key': ?instance.key,
  'mediaType': ?instance.mediaType,
};
