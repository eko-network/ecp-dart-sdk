import 'package:ecp/src/utils.dart';
import 'package:uuid/uuid.dart';

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

/// Base class for all ActivityPub objects, containing a unique ID and optional inReplyTo ID.
class ObjectBase {
  final UuidValue id;
  final UuidValue? inReplyTo;
  ObjectBase({required this.id, this.inReplyTo});

  factory ObjectBase.fromJson(Map<String, dynamic> json) {
    return ObjectBase(
      id: UuidValue.fromString(
        (json['id'] as String).replaceFirst('urn:uuid:', ''),
      ),
      inReplyTo: json['inReplyTo'] != null
          ? UuidValue.fromString(
              (json['inReplyTo'] as String).replaceFirst('urn:uuid:', ''),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': serializeUuid(id),
    if (inReplyTo != null) 'inReplyTo': serializeUuid(inReplyTo!),
  };
}

/// Represents a Note object.
class Note implements ActivityPubObject {
  final String? content;
  @override
  final ObjectBase base;
  final List<ActivityPubObject>? attachments;
  Note({required this.content, required this.base, this.attachments});
  @override
  String get type => 'Note';

  factory Note.fromJson(Map<String, dynamic> json) {
    final List<ActivityPubObject>? attachments = (json['attachments'] as List?)
        ?.map((v) => ActivityPubObject.fromJson(v))
        .toList();
    return Note(
      base: ObjectBase.fromJson(json),
      attachments: attachments,
      content: json['content'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    if (attachments != null) {
      json['attachments'] = attachments!.map((v) => v.toJson()).toList();
    }
    if (content != null) {
      json['content'] = content;
    }
    return json;
  }
}

/// Represents an emoji reaction to an object.
class EmojiReact implements ActivityPubObject {
  @override
  final ObjectBase base;
  final String content;

  //Maybe loosen the requirements so a custom emoji can be used?
  @override
  String get type => 'EmojiReact';
  EmojiReact({required this.base, required this.content})
    : assert(content.length == 1);

  factory EmojiReact.fromJson(Map<String, dynamic> json) {
    final String content = json['content'];
    if (content.length != 1) {
      throw Error();
    }
    return EmojiReact(base: ObjectBase.fromJson(json), content: content);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['content'] = content;
    return json;
  }
}

/// Represents a generic document, which can include various media types.
class Document implements ActivityPubObject {
  @override
  final ObjectBase base;
  final Uri url;
  final String encryption;
  final String key;
  final String? mediaType;

  Document({
    required this.base,
    required this.url,
    required this.encryption,
    required this.key,
    this.mediaType,
  });

  @override
  String get type => 'Document';

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      base: ObjectBase.fromJson(json),
      url: Uri.parse(json['url'] as String),
      encryption: json['encryption'] as String,
      key: json['key'] as String,
      mediaType: json['mediaType'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = base.toJson();
    json['type'] = type;
    json['url'] = url.toString();
    json['encryption'] = encryption;
    json['key'] = key;
    if (mediaType != null) {
      json['mediaType'] = mediaType;
    }
    return json;
  }
}

/// Represents an image document.
class Image extends Document {
  Image({
    required super.base,
    required super.url,
    required super.encryption,
    required super.key,
    super.mediaType,
  });

  @override
  String get type => 'Image';

  factory Image.fromJson(Map<String, dynamic> json) {
    return Image(
      base: ObjectBase.fromJson(json),
      url: Uri.parse(json['url'] as String),
      encryption: json['encryption'] as String,
      key: json['key'] as String,
      mediaType: json['mediaType'] as String?,
    );
  }
}

/// Represents a video document.
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

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      base: ObjectBase.fromJson(json),
      url: Uri.parse(json['url'] as String),
      encryption: json['encryption'] as String,
      key: json['key'] as String,
      mediaType: json['mediaType'] as String?,
    );
  }
}

/// Represents an audio document.
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

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(
      base: ObjectBase.fromJson(json),
      url: Uri.parse(json['url'] as String),
      encryption: json['encryption'] as String,
      key: json['key'] as String,
      mediaType: json['mediaType'] as String?,
    );
  }
}
