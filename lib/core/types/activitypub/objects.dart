import 'package:ecp/core/types/activitypub/internal_id.dart';
import 'package:ecp/core/utils/converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part '../../../generated/core/types/activitypub/objects.freezed.dart';
part '../../../generated/core/types/activitypub/objects.g.dart';

/// Represents a generic ActivityPub object.
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.pascal)
sealed class ActivityPubObject with _$ActivityPubObject {
  const ActivityPubObject._();

  const factory ActivityPubObject.note({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() InternalId? inReplyTo,
    String? content,
    List<ActivityPubObject>? attachments,
  }) = Note;

  const factory ActivityPubObject.emojiReact({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() InternalId? inReplyTo,
    required String content,
  }) = EmojiReact;

  const factory ActivityPubObject.document({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
    int? width,
    String? name,
    int? height,
  }) = Document;

  const factory ActivityPubObject.image({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
    int? width,
    String? name,
    int? height,
  }) = Image;

  const factory ActivityPubObject.video({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
  }) = Video;

  const factory ActivityPubObject.audio({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
  }) = Audio;

  factory ActivityPubObject.newNote({
    InternalId? id,
    InternalId? inReplyTo,
    String? content,
    List<ActivityPubObject>? attachments,
  }) =>
      ActivityPubObject.note(
        id: id ?? InternalId.gen(),
        inReplyTo: inReplyTo,
        content: content,
        attachments: attachments,
      );

  factory ActivityPubObject.newEmojiReact({
    InternalId? id,
    InternalId? inReplyTo,
    required String content,
  }) =>
      ActivityPubObject.emojiReact(
        id: id ?? InternalId.gen(),
        inReplyTo: inReplyTo,
        content: content,
      );

  factory ActivityPubObject.newDocument({
    InternalId? id,
    InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
    int? width,
    String? name,
    int? height,
  }) =>
      ActivityPubObject.document(
        id: id ?? InternalId.gen(),
        inReplyTo: inReplyTo,
        url: url,
        encryption: encryption,
        key: key,
        mediaType: mediaType,
        width: width,
        name: name,
        height: height,
      );

  factory ActivityPubObject.newImage({
    InternalId? id,
    InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
    int? width,
    String? name,
    int? height,
  }) =>
      ActivityPubObject.image(
        id: id ?? InternalId.gen(),
        inReplyTo: inReplyTo,
        url: url,
        encryption: encryption,
        key: key,
        mediaType: mediaType,
        width: width,
        name: name,
        height: height,
      );

  factory ActivityPubObject.newVideo({
    InternalId? id,
    InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
  }) =>
      ActivityPubObject.video(
        id: id ?? InternalId.gen(),
        inReplyTo: inReplyTo,
        url: url,
        encryption: encryption,
        key: key,
        mediaType: mediaType,
      );

  factory ActivityPubObject.newAudio({
    InternalId? id,
    InternalId? inReplyTo,
    @UriConverter() required Uri url,
    String? encryption,
    String? key,
    String? mediaType,
  }) =>
      ActivityPubObject.audio(
        id: id ?? InternalId.gen(),
        inReplyTo: inReplyTo,
        url: url,
        encryption: encryption,
        key: key,
        mediaType: mediaType,
      );

  factory ActivityPubObject.fromJson(Map<String, dynamic> json) =>
      _$ActivityPubObjectFromJson(json);

  InternalId get id => map(
    note: (v) => v.id,
    emojiReact: (v) => v.id,
    document: (v) => v.id,
    image: (v) => v.id,
    video: (v) => v.id,
    audio: (v) => v.id,
  );

  InternalId? get inReplyTo => map(
    note: (v) => v.inReplyTo,
    emojiReact: (v) => v.inReplyTo,
    document: (v) => v.inReplyTo,
    image: (v) => v.inReplyTo,
    video: (v) => v.inReplyTo,
    audio: (v) => v.inReplyTo,
  );

  String get type => map(
    note: (_) => 'Note',
    emojiReact: (_) => 'EmojiReact',
    document: (_) => 'Document',
    image: (_) => 'Image',
    video: (_) => 'Video',
    audio: (_) => 'Audio',
  );
}
