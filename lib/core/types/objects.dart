import 'package:ecp/core/utils/uuid.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part '../../generated/core/types/objects.g.dart';

/// Represents a generic ActivityPub object.
abstract class ActivityPubObject {
  ObjectBase get base;
  String get type;
  Map<String, dynamic> toJson();

  static final Map<
    String,
    ActivityPubObject Function(Map<String, dynamic> fromJson)
  >
  _factories = {
    'Note': Note.fromJson,
    'EmojiReact': EmojiReact.fromJson,
    'Document': Document.fromJson,
    'Image': Image.fromJson,
    'Video': Video.fromJson,
    'Audio': Audio.fromJson,
  };

  static void registerObject(
    String type,
    ActivityPubObject Function(Map<String, dynamic> fromJson) fromJson,
  ) {
    _factories[type] = fromJson;
  }

  factory ActivityPubObject.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('Object JSON must have a "type" field');
    }
    final factory = _factories[type];
    if (factory != null) {
      return factory(json);
    }
    throw UnsupportedError('Unknown object type: $type');
  }
}

class UuidConverter implements JsonConverter<UuidValue, String> {
  const UuidConverter();

  @override
  UuidValue fromJson(String json) => deserializeUuid(json);

  @override
  String toJson(UuidValue object) => serializeUuid(object);
}

// Helper to read the entire map for 'base' field
Object? _readBase(Map map, String key) => map;

/// Base class for all ActivityPub objects, containing a unique ID and optional inReplyTo ID.
@JsonSerializable(includeIfNull: false)
class ObjectBase {
  @UuidConverter()
  final UuidValue id;
  @UuidConverter()
  final UuidValue? inReplyTo;

  ObjectBase({required this.id, this.inReplyTo});

  factory ObjectBase.fromJson(Map<String, dynamic> json) =>
      _$ObjectBaseFromJson(json);

  Map<String, dynamic> toJson() => _$ObjectBaseToJson(this);
}

/// Represents a Note object.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Note implements ActivityPubObject {
  final String? content;

  @override
  @JsonKey(readValue: _readBase, includeToJson: false)
  final ObjectBase base;

  final List<ActivityPubObject>? attachments;

  Note({required this.content, required this.base, this.attachments});

  @override
  String get type => 'Note';

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$NoteToJson(this)
    ..addAll(base.toJson())
    ..['type'] = type;
}

/// Represents an emoji reaction to an object.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EmojiReact implements ActivityPubObject {
  @override
  @JsonKey(readValue: _readBase, includeToJson: false)
  final ObjectBase base;

  final String content;

  //Maybe loosen the requirements so a custom emoji can be used?
  @override
  String get type => 'EmojiReact';

  EmojiReact({required this.base, required this.content}) {
    if (content.length != 1) {
      throw ArgumentError('Content length must be 1');
    }
  }

  factory EmojiReact.fromJson(Map<String, dynamic> json) =>
      _$EmojiReactFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EmojiReactToJson(this)
    ..addAll(base.toJson())
    ..['type'] = type;
}

/// Represents a generic document, which can include various media types.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Document implements ActivityPubObject {
  @override
  @JsonKey(readValue: _readBase, includeToJson: false)
  final ObjectBase base;

  final Uri url;
  final String? encryption;
  final String? key;
  final String? mediaType;
  final int? width;
  final String? name;
  final int? height;

  Document({
    required this.base,
    required this.url,
    this.encryption,
    this.key,
    this.mediaType,
    this.name,
    this.width,
    this.height,
  });

  @override
  String get type => 'Document';

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DocumentToJson(this)
    ..addAll(base.toJson())
    ..['type'] = type;
}

/// Represents an image document.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Image extends Document {
  Image({
    required super.base,
    required super.url,
    super.encryption,
    super.key,
    super.width,
    super.name,
    super.height,
    super.mediaType,
  });

  @override
  String get type => 'Image';

  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ImageToJson(this)
    ..addAll(base.toJson())
    ..['type'] = type;
}

/// Represents a video document.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Video extends Document {
  Video({
    required super.base,
    required super.url,
    required super.encryption,
    required super.key,
    super.mediaType,
  });

  @override
  String get type => 'Video';

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VideoToJson(this)
    ..addAll(base.toJson())
    ..['type'] = type;
}

/// Represents an audio document.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Audio extends Document {
  Audio({
    required super.base,
    required super.url,
    required super.encryption,
    required super.key,
    super.mediaType,
  });

  @override
  String get type => 'Audio';

  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AudioToJson(this)
    ..addAll(base.toJson())
    ..['type'] = type;
}
