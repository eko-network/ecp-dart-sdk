// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../core/types/activitypub/objects.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ActivityPubObject _$ActivityPubObjectFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'Note':
          return Note.fromJson(
            json
          );
                case 'EmojiReact':
          return EmojiReact.fromJson(
            json
          );
                case 'Document':
          return Document.fromJson(
            json
          );
                case 'Image':
          return Image.fromJson(
            json
          );
                case 'Video':
          return Video.fromJson(
            json
          );
                case 'Audio':
          return Audio.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ActivityPubObject',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ActivityPubObject {

@InternalIdConverter() InternalId get id;@InternalIdConverter() InternalId? get inReplyTo;
/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityPubObjectCopyWith<ActivityPubObject> get copyWith => _$ActivityPubObjectCopyWithImpl<ActivityPubObject>(this as ActivityPubObject, _$identity);

  /// Serializes this ActivityPubObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityPubObject&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo);

@override
String toString() {
  return 'ActivityPubObject(id: $id, inReplyTo: $inReplyTo)';
}


}

/// @nodoc
abstract mixin class $ActivityPubObjectCopyWith<$Res>  {
  factory $ActivityPubObjectCopyWith(ActivityPubObject value, $Res Function(ActivityPubObject) _then) = _$ActivityPubObjectCopyWithImpl;
@useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo
});




}
/// @nodoc
class _$ActivityPubObjectCopyWithImpl<$Res>
    implements $ActivityPubObjectCopyWith<$Res> {
  _$ActivityPubObjectCopyWithImpl(this._self, this._then);

  final ActivityPubObject _self;
  final $Res Function(ActivityPubObject) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? inReplyTo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityPubObject].
extension ActivityPubObjectPatterns on ActivityPubObject {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Note value)?  note,TResult Function( EmojiReact value)?  emojiReact,TResult Function( Document value)?  document,TResult Function( Image value)?  image,TResult Function( Video value)?  video,TResult Function( Audio value)?  audio,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Note() when note != null:
return note(_that);case EmojiReact() when emojiReact != null:
return emojiReact(_that);case Document() when document != null:
return document(_that);case Image() when image != null:
return image(_that);case Video() when video != null:
return video(_that);case Audio() when audio != null:
return audio(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Note value)  note,required TResult Function( EmojiReact value)  emojiReact,required TResult Function( Document value)  document,required TResult Function( Image value)  image,required TResult Function( Video value)  video,required TResult Function( Audio value)  audio,}){
final _that = this;
switch (_that) {
case Note():
return note(_that);case EmojiReact():
return emojiReact(_that);case Document():
return document(_that);case Image():
return image(_that);case Video():
return video(_that);case Audio():
return audio(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Note value)?  note,TResult? Function( EmojiReact value)?  emojiReact,TResult? Function( Document value)?  document,TResult? Function( Image value)?  image,TResult? Function( Video value)?  video,TResult? Function( Audio value)?  audio,}){
final _that = this;
switch (_that) {
case Note() when note != null:
return note(_that);case EmojiReact() when emojiReact != null:
return emojiReact(_that);case Document() when document != null:
return document(_that);case Image() when image != null:
return image(_that);case Video() when video != null:
return video(_that);case Audio() when audio != null:
return audio(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo,  String? content,  List<ActivityPubObject>? attachments)?  note,TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo,  String content)?  emojiReact,TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType,  int? width,  String? name,  int? height)?  document,TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType,  int? width,  String? name,  int? height)?  image,TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType)?  video,TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType)?  audio,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Note() when note != null:
return note(_that.id,_that.inReplyTo,_that.content,_that.attachments);case EmojiReact() when emojiReact != null:
return emojiReact(_that.id,_that.inReplyTo,_that.content);case Document() when document != null:
return document(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType,_that.width,_that.name,_that.height);case Image() when image != null:
return image(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType,_that.width,_that.name,_that.height);case Video() when video != null:
return video(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType);case Audio() when audio != null:
return audio(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo,  String? content,  List<ActivityPubObject>? attachments)  note,required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo,  String content)  emojiReact,required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType,  int? width,  String? name,  int? height)  document,required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType,  int? width,  String? name,  int? height)  image,required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType)  video,required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType)  audio,}) {final _that = this;
switch (_that) {
case Note():
return note(_that.id,_that.inReplyTo,_that.content,_that.attachments);case EmojiReact():
return emojiReact(_that.id,_that.inReplyTo,_that.content);case Document():
return document(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType,_that.width,_that.name,_that.height);case Image():
return image(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType,_that.width,_that.name,_that.height);case Video():
return video(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType);case Audio():
return audio(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo,  String? content,  List<ActivityPubObject>? attachments)?  note,TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo,  String content)?  emojiReact,TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType,  int? width,  String? name,  int? height)?  document,TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType,  int? width,  String? name,  int? height)?  image,TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType)?  video,TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  InternalId? inReplyTo, @UriConverter()  Uri url,  String? encryption,  String? key,  String? mediaType)?  audio,}) {final _that = this;
switch (_that) {
case Note() when note != null:
return note(_that.id,_that.inReplyTo,_that.content,_that.attachments);case EmojiReact() when emojiReact != null:
return emojiReact(_that.id,_that.inReplyTo,_that.content);case Document() when document != null:
return document(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType,_that.width,_that.name,_that.height);case Image() when image != null:
return image(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType,_that.width,_that.name,_that.height);case Video() when video != null:
return video(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType);case Audio() when audio != null:
return audio(_that.id,_that.inReplyTo,_that.url,_that.encryption,_that.key,_that.mediaType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Note extends ActivityPubObject {
  const Note({@InternalIdConverter() required this.id, @InternalIdConverter() this.inReplyTo, this.content, final  List<ActivityPubObject>? attachments, final  String? $type}): _attachments = attachments,$type = $type ?? 'Note',super._();
  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

@override@InternalIdConverter() final  InternalId id;
@override@InternalIdConverter() final  InternalId? inReplyTo;
 final  String? content;
 final  List<ActivityPubObject>? _attachments;
 List<ActivityPubObject>? get attachments {
  final value = _attachments;
  if (value == null) return null;
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteCopyWith<Note> get copyWith => _$NoteCopyWithImpl<Note>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Note&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo,content,const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'ActivityPubObject.note(id: $id, inReplyTo: $inReplyTo, content: $content, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $NoteCopyWith<$Res> implements $ActivityPubObjectCopyWith<$Res> {
  factory $NoteCopyWith(Note value, $Res Function(Note) _then) = _$NoteCopyWithImpl;
@override @useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo, String? content, List<ActivityPubObject>? attachments
});




}
/// @nodoc
class _$NoteCopyWithImpl<$Res>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._self, this._then);

  final Note _self;
  final $Res Function(Note) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inReplyTo = freezed,Object? content = freezed,Object? attachments = freezed,}) {
  return _then(Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,attachments: freezed == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<ActivityPubObject>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class EmojiReact extends ActivityPubObject {
  const EmojiReact({@InternalIdConverter() required this.id, @InternalIdConverter() this.inReplyTo, required this.content, final  String? $type}): $type = $type ?? 'EmojiReact',super._();
  factory EmojiReact.fromJson(Map<String, dynamic> json) => _$EmojiReactFromJson(json);

@override@InternalIdConverter() final  InternalId id;
@override@InternalIdConverter() final  InternalId? inReplyTo;
 final  String content;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmojiReactCopyWith<EmojiReact> get copyWith => _$EmojiReactCopyWithImpl<EmojiReact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmojiReactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmojiReact&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo,content);

@override
String toString() {
  return 'ActivityPubObject.emojiReact(id: $id, inReplyTo: $inReplyTo, content: $content)';
}


}

/// @nodoc
abstract mixin class $EmojiReactCopyWith<$Res> implements $ActivityPubObjectCopyWith<$Res> {
  factory $EmojiReactCopyWith(EmojiReact value, $Res Function(EmojiReact) _then) = _$EmojiReactCopyWithImpl;
@override @useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo, String content
});




}
/// @nodoc
class _$EmojiReactCopyWithImpl<$Res>
    implements $EmojiReactCopyWith<$Res> {
  _$EmojiReactCopyWithImpl(this._self, this._then);

  final EmojiReact _self;
  final $Res Function(EmojiReact) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inReplyTo = freezed,Object? content = null,}) {
  return _then(EmojiReact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Document extends ActivityPubObject {
  const Document({@InternalIdConverter() required this.id, @InternalIdConverter() this.inReplyTo, @UriConverter() required this.url, this.encryption, this.key, this.mediaType, this.width, this.name, this.height, final  String? $type}): $type = $type ?? 'Document',super._();
  factory Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);

@override@InternalIdConverter() final  InternalId id;
@override@InternalIdConverter() final  InternalId? inReplyTo;
@UriConverter() final  Uri url;
 final  String? encryption;
 final  String? key;
 final  String? mediaType;
 final  int? width;
 final  String? name;
 final  int? height;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo)&&(identical(other.url, url) || other.url == url)&&(identical(other.encryption, encryption) || other.encryption == encryption)&&(identical(other.key, key) || other.key == key)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.width, width) || other.width == width)&&(identical(other.name, name) || other.name == name)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo,url,encryption,key,mediaType,width,name,height);

@override
String toString() {
  return 'ActivityPubObject.document(id: $id, inReplyTo: $inReplyTo, url: $url, encryption: $encryption, key: $key, mediaType: $mediaType, width: $width, name: $name, height: $height)';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res> implements $ActivityPubObjectCopyWith<$Res> {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@override @useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo,@UriConverter() Uri url, String? encryption, String? key, String? mediaType, int? width, String? name, int? height
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inReplyTo = freezed,Object? url = null,Object? encryption = freezed,Object? key = freezed,Object? mediaType = freezed,Object? width = freezed,Object? name = freezed,Object? height = freezed,}) {
  return _then(Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,encryption: freezed == encryption ? _self.encryption : encryption // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Image extends ActivityPubObject {
  const Image({@InternalIdConverter() required this.id, @InternalIdConverter() this.inReplyTo, @UriConverter() required this.url, this.encryption, this.key, this.mediaType, this.width, this.name, this.height, final  String? $type}): $type = $type ?? 'Image',super._();
  factory Image.fromJson(Map<String, dynamic> json) => _$ImageFromJson(json);

@override@InternalIdConverter() final  InternalId id;
@override@InternalIdConverter() final  InternalId? inReplyTo;
@UriConverter() final  Uri url;
 final  String? encryption;
 final  String? key;
 final  String? mediaType;
 final  int? width;
 final  String? name;
 final  int? height;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageCopyWith<Image> get copyWith => _$ImageCopyWithImpl<Image>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Image&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo)&&(identical(other.url, url) || other.url == url)&&(identical(other.encryption, encryption) || other.encryption == encryption)&&(identical(other.key, key) || other.key == key)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.width, width) || other.width == width)&&(identical(other.name, name) || other.name == name)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo,url,encryption,key,mediaType,width,name,height);

@override
String toString() {
  return 'ActivityPubObject.image(id: $id, inReplyTo: $inReplyTo, url: $url, encryption: $encryption, key: $key, mediaType: $mediaType, width: $width, name: $name, height: $height)';
}


}

/// @nodoc
abstract mixin class $ImageCopyWith<$Res> implements $ActivityPubObjectCopyWith<$Res> {
  factory $ImageCopyWith(Image value, $Res Function(Image) _then) = _$ImageCopyWithImpl;
@override @useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo,@UriConverter() Uri url, String? encryption, String? key, String? mediaType, int? width, String? name, int? height
});




}
/// @nodoc
class _$ImageCopyWithImpl<$Res>
    implements $ImageCopyWith<$Res> {
  _$ImageCopyWithImpl(this._self, this._then);

  final Image _self;
  final $Res Function(Image) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inReplyTo = freezed,Object? url = null,Object? encryption = freezed,Object? key = freezed,Object? mediaType = freezed,Object? width = freezed,Object? name = freezed,Object? height = freezed,}) {
  return _then(Image(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,encryption: freezed == encryption ? _self.encryption : encryption // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Video extends ActivityPubObject {
  const Video({@InternalIdConverter() required this.id, @InternalIdConverter() this.inReplyTo, @UriConverter() required this.url, this.encryption, this.key, this.mediaType, final  String? $type}): $type = $type ?? 'Video',super._();
  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

@override@InternalIdConverter() final  InternalId id;
@override@InternalIdConverter() final  InternalId? inReplyTo;
@UriConverter() final  Uri url;
 final  String? encryption;
 final  String? key;
 final  String? mediaType;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCopyWith<Video> get copyWith => _$VideoCopyWithImpl<Video>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Video&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo)&&(identical(other.url, url) || other.url == url)&&(identical(other.encryption, encryption) || other.encryption == encryption)&&(identical(other.key, key) || other.key == key)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo,url,encryption,key,mediaType);

@override
String toString() {
  return 'ActivityPubObject.video(id: $id, inReplyTo: $inReplyTo, url: $url, encryption: $encryption, key: $key, mediaType: $mediaType)';
}


}

/// @nodoc
abstract mixin class $VideoCopyWith<$Res> implements $ActivityPubObjectCopyWith<$Res> {
  factory $VideoCopyWith(Video value, $Res Function(Video) _then) = _$VideoCopyWithImpl;
@override @useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo,@UriConverter() Uri url, String? encryption, String? key, String? mediaType
});




}
/// @nodoc
class _$VideoCopyWithImpl<$Res>
    implements $VideoCopyWith<$Res> {
  _$VideoCopyWithImpl(this._self, this._then);

  final Video _self;
  final $Res Function(Video) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inReplyTo = freezed,Object? url = null,Object? encryption = freezed,Object? key = freezed,Object? mediaType = freezed,}) {
  return _then(Video(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,encryption: freezed == encryption ? _self.encryption : encryption // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Audio extends ActivityPubObject {
  const Audio({@InternalIdConverter() required this.id, @InternalIdConverter() this.inReplyTo, @UriConverter() required this.url, this.encryption, this.key, this.mediaType, final  String? $type}): $type = $type ?? 'Audio',super._();
  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);

@override@InternalIdConverter() final  InternalId id;
@override@InternalIdConverter() final  InternalId? inReplyTo;
@UriConverter() final  Uri url;
 final  String? encryption;
 final  String? key;
 final  String? mediaType;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioCopyWith<Audio> get copyWith => _$AudioCopyWithImpl<Audio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Audio&&(identical(other.id, id) || other.id == id)&&(identical(other.inReplyTo, inReplyTo) || other.inReplyTo == inReplyTo)&&(identical(other.url, url) || other.url == url)&&(identical(other.encryption, encryption) || other.encryption == encryption)&&(identical(other.key, key) || other.key == key)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inReplyTo,url,encryption,key,mediaType);

@override
String toString() {
  return 'ActivityPubObject.audio(id: $id, inReplyTo: $inReplyTo, url: $url, encryption: $encryption, key: $key, mediaType: $mediaType)';
}


}

/// @nodoc
abstract mixin class $AudioCopyWith<$Res> implements $ActivityPubObjectCopyWith<$Res> {
  factory $AudioCopyWith(Audio value, $Res Function(Audio) _then) = _$AudioCopyWithImpl;
@override @useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() InternalId? inReplyTo,@UriConverter() Uri url, String? encryption, String? key, String? mediaType
});




}
/// @nodoc
class _$AudioCopyWithImpl<$Res>
    implements $AudioCopyWith<$Res> {
  _$AudioCopyWithImpl(this._self, this._then);

  final Audio _self;
  final $Res Function(Audio) _then;

/// Create a copy of ActivityPubObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inReplyTo = freezed,Object? url = null,Object? encryption = freezed,Object? key = freezed,Object? mediaType = freezed,}) {
  return _then(Audio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,inReplyTo: freezed == inReplyTo ? _self.inReplyTo : inReplyTo // ignore: cast_nullable_to_non_nullable
as InternalId?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,encryption: freezed == encryption ? _self.encryption : encryption // ignore: cast_nullable_to_non_nullable
as String?,key: freezed == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
