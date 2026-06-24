// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../core/types/activitypub/wire_objects.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
WireObject _$WireObjectFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'ApprovalRequest':
          return ApprovalRequest.fromJson(
            json
          );
                case 'PrivateMessage':
          return PrivateMessage.fromJson(
            json
          );
                case 'WelcomeMessage':
          return WelcomeMessage.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'WireObject',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$WireObject {

@JsonKey(name: '@context') Object? get context;@UriConverter() Uri? get id;@UriConverter() Uri get actor;@UriConverter() List<Uri> get to;
/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireObjectCopyWith<WireObject> get copyWith => _$WireObjectCopyWithImpl<WireObject>(this as WireObject, _$identity);

  /// Serializes this WireObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireObject&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other.to, to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,actor,const DeepCollectionEquality().hash(to));

@override
String toString() {
  return 'WireObject(context: $context, id: $id, actor: $actor, to: $to)';
}


}

/// @nodoc
abstract mixin class $WireObjectCopyWith<$Res>  {
  factory $WireObjectCopyWith(WireObject value, $Res Function(WireObject) _then) = _$WireObjectCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() Uri actor,@UriConverter() List<Uri> to
});




}
/// @nodoc
class _$WireObjectCopyWithImpl<$Res>
    implements $WireObjectCopyWith<$Res> {
  _$WireObjectCopyWithImpl(this._self, this._then);

  final WireObject _self;
  final $Res Function(WireObject) _then;

/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? context = freezed,Object? id = freezed,Object? actor = null,Object? to = null,}) {
  return _then(_self.copyWith(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,
  ));
}

}


/// Adds pattern-matching-related methods to [WireObject].
extension WireObjectPatterns on WireObject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ApprovalRequest value)?  approvalRequest,TResult Function( PrivateMessage value)?  privateMessage,TResult Function( WelcomeMessage value)?  welcomeMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ApprovalRequest() when approvalRequest != null:
return approvalRequest(_that);case PrivateMessage() when privateMessage != null:
return privateMessage(_that);case WelcomeMessage() when welcomeMessage != null:
return welcomeMessage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ApprovalRequest value)  approvalRequest,required TResult Function( PrivateMessage value)  privateMessage,required TResult Function( WelcomeMessage value)  welcomeMessage,}){
final _that = this;
switch (_that) {
case ApprovalRequest():
return approvalRequest(_that);case PrivateMessage():
return privateMessage(_that);case WelcomeMessage():
return welcomeMessage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ApprovalRequest value)?  approvalRequest,TResult? Function( PrivateMessage value)?  privateMessage,TResult? Function( WelcomeMessage value)?  welcomeMessage,}){
final _that = this;
switch (_that) {
case ApprovalRequest() when approvalRequest != null:
return approvalRequest(_that);case PrivateMessage() when privateMessage != null:
return privateMessage(_that);case WelcomeMessage() when welcomeMessage != null:
return welcomeMessage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List publicKey,  String did)?  approvalRequest,TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List content)?  privateMessage,TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List content)?  welcomeMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ApprovalRequest() when approvalRequest != null:
return approvalRequest(_that.context,_that.id,_that.actor,_that.to,_that.publicKey,_that.did);case PrivateMessage() when privateMessage != null:
return privateMessage(_that.context,_that.id,_that.actor,_that.to,_that.content);case WelcomeMessage() when welcomeMessage != null:
return welcomeMessage(_that.context,_that.id,_that.actor,_that.to,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List publicKey,  String did)  approvalRequest,required TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List content)  privateMessage,required TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List content)  welcomeMessage,}) {final _that = this;
switch (_that) {
case ApprovalRequest():
return approvalRequest(_that.context,_that.id,_that.actor,_that.to,_that.publicKey,_that.did);case PrivateMessage():
return privateMessage(_that.context,_that.id,_that.actor,_that.to,_that.content);case WelcomeMessage():
return welcomeMessage(_that.context,_that.id,_that.actor,_that.to,_that.content);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List publicKey,  String did)?  approvalRequest,TResult? Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List content)?  privateMessage,TResult? Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  Uri actor, @UriConverter()  List<Uri> to, @Uint8ListConverter()  Uint8List content)?  welcomeMessage,}) {final _that = this;
switch (_that) {
case ApprovalRequest() when approvalRequest != null:
return approvalRequest(_that.context,_that.id,_that.actor,_that.to,_that.publicKey,_that.did);case PrivateMessage() when privateMessage != null:
return privateMessage(_that.context,_that.id,_that.actor,_that.to,_that.content);case WelcomeMessage() when welcomeMessage != null:
return welcomeMessage(_that.context,_that.id,_that.actor,_that.to,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ApprovalRequest extends WireObject {
  const ApprovalRequest({@JsonKey(name: '@context') this.context = ecpJsonLdContext, @UriConverter() this.id, @UriConverter() required this.actor, @UriConverter() required final  List<Uri> to, @Uint8ListConverter() required this.publicKey, required this.did, final  String? $type}): _to = to,$type = $type ?? 'ApprovalRequest',super._();
  factory ApprovalRequest.fromJson(Map<String, dynamic> json) => _$ApprovalRequestFromJson(json);

@override@JsonKey(name: '@context') final  Object? context;
@override@UriConverter() final  Uri? id;
@override@UriConverter() final  Uri actor;
 final  List<Uri> _to;
@override@UriConverter() List<Uri> get to {
  if (_to is EqualUnmodifiableListView) return _to;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_to);
}

@Uint8ListConverter() final  Uint8List publicKey;
 final  String did;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalRequestCopyWith<ApprovalRequest> get copyWith => _$ApprovalRequestCopyWithImpl<ApprovalRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApprovalRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalRequest&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other._to, _to)&&const DeepCollectionEquality().equals(other.publicKey, publicKey)&&(identical(other.did, did) || other.did == did));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,actor,const DeepCollectionEquality().hash(_to),const DeepCollectionEquality().hash(publicKey),did);

@override
String toString() {
  return 'WireObject.approvalRequest(context: $context, id: $id, actor: $actor, to: $to, publicKey: $publicKey, did: $did)';
}


}

/// @nodoc
abstract mixin class $ApprovalRequestCopyWith<$Res> implements $WireObjectCopyWith<$Res> {
  factory $ApprovalRequestCopyWith(ApprovalRequest value, $Res Function(ApprovalRequest) _then) = _$ApprovalRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() Uri actor,@UriConverter() List<Uri> to,@Uint8ListConverter() Uint8List publicKey, String did
});




}
/// @nodoc
class _$ApprovalRequestCopyWithImpl<$Res>
    implements $ApprovalRequestCopyWith<$Res> {
  _$ApprovalRequestCopyWithImpl(this._self, this._then);

  final ApprovalRequest _self;
  final $Res Function(ApprovalRequest) _then;

/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? id = freezed,Object? actor = null,Object? to = null,Object? publicKey = null,Object? did = null,}) {
  return _then(ApprovalRequest(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,to: null == to ? _self._to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as Uint8List,did: null == did ? _self.did : did // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PrivateMessage extends WireObject {
  const PrivateMessage({@JsonKey(name: '@context') this.context = ecpJsonLdContext, @UriConverter() this.id, @UriConverter() required this.actor, @UriConverter() required final  List<Uri> to, @Uint8ListConverter() required this.content, final  String? $type}): _to = to,$type = $type ?? 'PrivateMessage',super._();
  factory PrivateMessage.fromJson(Map<String, dynamic> json) => _$PrivateMessageFromJson(json);

@override@JsonKey(name: '@context') final  Object? context;
@override@UriConverter() final  Uri? id;
@override@UriConverter() final  Uri actor;
 final  List<Uri> _to;
@override@UriConverter() List<Uri> get to {
  if (_to is EqualUnmodifiableListView) return _to;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_to);
}

@Uint8ListConverter() final  Uint8List content;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivateMessageCopyWith<PrivateMessage> get copyWith => _$PrivateMessageCopyWithImpl<PrivateMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrivateMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivateMessage&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other._to, _to)&&const DeepCollectionEquality().equals(other.content, content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,actor,const DeepCollectionEquality().hash(_to),const DeepCollectionEquality().hash(content));

@override
String toString() {
  return 'WireObject.privateMessage(context: $context, id: $id, actor: $actor, to: $to, content: $content)';
}


}

/// @nodoc
abstract mixin class $PrivateMessageCopyWith<$Res> implements $WireObjectCopyWith<$Res> {
  factory $PrivateMessageCopyWith(PrivateMessage value, $Res Function(PrivateMessage) _then) = _$PrivateMessageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() Uri actor,@UriConverter() List<Uri> to,@Uint8ListConverter() Uint8List content
});




}
/// @nodoc
class _$PrivateMessageCopyWithImpl<$Res>
    implements $PrivateMessageCopyWith<$Res> {
  _$PrivateMessageCopyWithImpl(this._self, this._then);

  final PrivateMessage _self;
  final $Res Function(PrivateMessage) _then;

/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? id = freezed,Object? actor = null,Object? to = null,Object? content = null,}) {
  return _then(PrivateMessage(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,to: null == to ? _self._to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
@JsonSerializable()

class WelcomeMessage extends WireObject {
  const WelcomeMessage({@JsonKey(name: '@context') this.context = ecpJsonLdContext, @UriConverter() this.id, @UriConverter() required this.actor, @UriConverter() required final  List<Uri> to, @Uint8ListConverter() required this.content, final  String? $type}): _to = to,$type = $type ?? 'WelcomeMessage',super._();
  factory WelcomeMessage.fromJson(Map<String, dynamic> json) => _$WelcomeMessageFromJson(json);

@override@JsonKey(name: '@context') final  Object? context;
@override@UriConverter() final  Uri? id;
@override@UriConverter() final  Uri actor;
 final  List<Uri> _to;
@override@UriConverter() List<Uri> get to {
  if (_to is EqualUnmodifiableListView) return _to;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_to);
}

@Uint8ListConverter() final  Uint8List content;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WelcomeMessageCopyWith<WelcomeMessage> get copyWith => _$WelcomeMessageCopyWithImpl<WelcomeMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WelcomeMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WelcomeMessage&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other._to, _to)&&const DeepCollectionEquality().equals(other.content, content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,actor,const DeepCollectionEquality().hash(_to),const DeepCollectionEquality().hash(content));

@override
String toString() {
  return 'WireObject.welcomeMessage(context: $context, id: $id, actor: $actor, to: $to, content: $content)';
}


}

/// @nodoc
abstract mixin class $WelcomeMessageCopyWith<$Res> implements $WireObjectCopyWith<$Res> {
  factory $WelcomeMessageCopyWith(WelcomeMessage value, $Res Function(WelcomeMessage) _then) = _$WelcomeMessageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() Uri actor,@UriConverter() List<Uri> to,@Uint8ListConverter() Uint8List content
});




}
/// @nodoc
class _$WelcomeMessageCopyWithImpl<$Res>
    implements $WelcomeMessageCopyWith<$Res> {
  _$WelcomeMessageCopyWithImpl(this._self, this._then);

  final WelcomeMessage _self;
  final $Res Function(WelcomeMessage) _then;

/// Create a copy of WireObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? id = freezed,Object? actor = null,Object? to = null,Object? content = null,}) {
  return _then(WelcomeMessage(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,to: null == to ? _self._to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

// dart format on
