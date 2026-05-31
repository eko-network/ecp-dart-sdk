// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../core/types/activitypub/wire_activities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
WireActivity _$WireActivityFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'Take':
          return WireTake.fromJson(
            json
          );
                case 'Create':
          return WireCreate.fromJson(
            json
          );
                case 'Delivered':
          return WireDelivered.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'WireActivity',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$WireActivity {

@JsonKey(name: '@context') Object? get context;@UriConverter() Uri? get id;@UriConverter() List<Uri> get to;@UriConverter() Uri get actor;
/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireActivityCopyWith<WireActivity> get copyWith => _$WireActivityCopyWithImpl<WireActivity>(this as WireActivity, _$identity);

  /// Serializes this WireActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireActivity&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.to, to)&&(identical(other.actor, actor) || other.actor == actor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,const DeepCollectionEquality().hash(to),actor);

@override
String toString() {
  return 'WireActivity(context: $context, id: $id, to: $to, actor: $actor)';
}


}

/// @nodoc
abstract mixin class $WireActivityCopyWith<$Res>  {
  factory $WireActivityCopyWith(WireActivity value, $Res Function(WireActivity) _then) = _$WireActivityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() List<Uri> to,@UriConverter() Uri actor
});




}
/// @nodoc
class _$WireActivityCopyWithImpl<$Res>
    implements $WireActivityCopyWith<$Res> {
  _$WireActivityCopyWithImpl(this._self, this._then);

  final WireActivity _self;
  final $Res Function(WireActivity) _then;

/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? context = freezed,Object? id = freezed,Object? to = null,Object? actor = null,}) {
  return _then(_self.copyWith(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}

}


/// Adds pattern-matching-related methods to [WireActivity].
extension WireActivityPatterns on WireActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WireTake value)?  wireTake,TResult Function( WireCreate value)?  wireCreate,TResult Function( WireDelivered value)?  wireDelivered,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WireTake() when wireTake != null:
return wireTake(_that);case WireCreate() when wireCreate != null:
return wireCreate(_that);case WireDelivered() when wireDelivered != null:
return wireDelivered(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WireTake value)  wireTake,required TResult Function( WireCreate value)  wireCreate,required TResult Function( WireDelivered value)  wireDelivered,}){
final _that = this;
switch (_that) {
case WireTake():
return wireTake(_that);case WireCreate():
return wireCreate(_that);case WireDelivered():
return wireDelivered(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WireTake value)?  wireTake,TResult? Function( WireCreate value)?  wireCreate,TResult? Function( WireDelivered value)?  wireDelivered,}){
final _that = this;
switch (_that) {
case WireTake() when wireTake != null:
return wireTake(_that);case WireCreate() when wireCreate != null:
return wireCreate(_that);case WireDelivered() when wireDelivered != null:
return wireDelivered(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to, @UriConverter()  Uri actor, @KeyPackageConvertor()  KeyPackage? result)?  wireTake,TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to,  WireObject object, @UriConverter()  Uri actor)?  wireCreate,TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to, @UriConverter()  Uri object, @UriConverter()  Uri actor)?  wireDelivered,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WireTake() when wireTake != null:
return wireTake(_that.context,_that.id,_that.to,_that.actor,_that.result);case WireCreate() when wireCreate != null:
return wireCreate(_that.context,_that.id,_that.to,_that.object,_that.actor);case WireDelivered() when wireDelivered != null:
return wireDelivered(_that.context,_that.id,_that.to,_that.object,_that.actor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to, @UriConverter()  Uri actor, @KeyPackageConvertor()  KeyPackage? result)  wireTake,required TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to,  WireObject object, @UriConverter()  Uri actor)  wireCreate,required TResult Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to, @UriConverter()  Uri object, @UriConverter()  Uri actor)  wireDelivered,}) {final _that = this;
switch (_that) {
case WireTake():
return wireTake(_that.context,_that.id,_that.to,_that.actor,_that.result);case WireCreate():
return wireCreate(_that.context,_that.id,_that.to,_that.object,_that.actor);case WireDelivered():
return wireDelivered(_that.context,_that.id,_that.to,_that.object,_that.actor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to, @UriConverter()  Uri actor, @KeyPackageConvertor()  KeyPackage? result)?  wireTake,TResult? Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to,  WireObject object, @UriConverter()  Uri actor)?  wireCreate,TResult? Function(@JsonKey(name: '@context')  Object? context, @UriConverter()  Uri? id, @UriConverter()  List<Uri> to, @UriConverter()  Uri object, @UriConverter()  Uri actor)?  wireDelivered,}) {final _that = this;
switch (_that) {
case WireTake() when wireTake != null:
return wireTake(_that.context,_that.id,_that.to,_that.actor,_that.result);case WireCreate() when wireCreate != null:
return wireCreate(_that.context,_that.id,_that.to,_that.object,_that.actor);case WireDelivered() when wireDelivered != null:
return wireDelivered(_that.context,_that.id,_that.to,_that.object,_that.actor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class WireTake extends WireActivity {
  const WireTake({@JsonKey(name: '@context') this.context = ecpJsonLdContext, @UriConverter() this.id, @UriConverter() required final  List<Uri> to, @UriConverter() required this.actor, @KeyPackageConvertor() this.result, final  String? $type}): _to = to,$type = $type ?? 'Take',super._();
  factory WireTake.fromJson(Map<String, dynamic> json) => _$WireTakeFromJson(json);

@override@JsonKey(name: '@context') final  Object? context;
@override@UriConverter() final  Uri? id;
 final  List<Uri> _to;
@override@UriConverter() List<Uri> get to {
  if (_to is EqualUnmodifiableListView) return _to;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_to);
}

@override@UriConverter() final  Uri actor;
@KeyPackageConvertor() final  KeyPackage? result;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireTakeCopyWith<WireTake> get copyWith => _$WireTakeCopyWithImpl<WireTake>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WireTakeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireTake&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._to, _to)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,const DeepCollectionEquality().hash(_to),actor,result);

@override
String toString() {
  return 'WireActivity.wireTake(context: $context, id: $id, to: $to, actor: $actor, result: $result)';
}


}

/// @nodoc
abstract mixin class $WireTakeCopyWith<$Res> implements $WireActivityCopyWith<$Res> {
  factory $WireTakeCopyWith(WireTake value, $Res Function(WireTake) _then) = _$WireTakeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() List<Uri> to,@UriConverter() Uri actor,@KeyPackageConvertor() KeyPackage? result
});




}
/// @nodoc
class _$WireTakeCopyWithImpl<$Res>
    implements $WireTakeCopyWith<$Res> {
  _$WireTakeCopyWithImpl(this._self, this._then);

  final WireTake _self;
  final $Res Function(WireTake) _then;

/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? id = freezed,Object? to = null,Object? actor = null,Object? result = freezed,}) {
  return _then(WireTake(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,to: null == to ? _self._to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as KeyPackage?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class WireCreate extends WireActivity {
  const WireCreate({@JsonKey(name: '@context') this.context = ecpJsonLdContext, @UriConverter() this.id, @UriConverter() required final  List<Uri> to, required this.object, @UriConverter() required this.actor, final  String? $type}): _to = to,$type = $type ?? 'Create',super._();
  factory WireCreate.fromJson(Map<String, dynamic> json) => _$WireCreateFromJson(json);

@override@JsonKey(name: '@context') final  Object? context;
@override@UriConverter() final  Uri? id;
 final  List<Uri> _to;
@override@UriConverter() List<Uri> get to {
  if (_to is EqualUnmodifiableListView) return _to;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_to);
}

 final  WireObject object;
@override@UriConverter() final  Uri actor;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireCreateCopyWith<WireCreate> get copyWith => _$WireCreateCopyWithImpl<WireCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WireCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireCreate&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._to, _to)&&(identical(other.object, object) || other.object == object)&&(identical(other.actor, actor) || other.actor == actor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,const DeepCollectionEquality().hash(_to),object,actor);

@override
String toString() {
  return 'WireActivity.wireCreate(context: $context, id: $id, to: $to, object: $object, actor: $actor)';
}


}

/// @nodoc
abstract mixin class $WireCreateCopyWith<$Res> implements $WireActivityCopyWith<$Res> {
  factory $WireCreateCopyWith(WireCreate value, $Res Function(WireCreate) _then) = _$WireCreateCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() List<Uri> to, WireObject object,@UriConverter() Uri actor
});


$WireObjectCopyWith<$Res> get object;

}
/// @nodoc
class _$WireCreateCopyWithImpl<$Res>
    implements $WireCreateCopyWith<$Res> {
  _$WireCreateCopyWithImpl(this._self, this._then);

  final WireCreate _self;
  final $Res Function(WireCreate) _then;

/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? id = freezed,Object? to = null,Object? object = null,Object? actor = null,}) {
  return _then(WireCreate(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,to: null == to ? _self._to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,object: null == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as WireObject,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}

/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WireObjectCopyWith<$Res> get object {
  
  return $WireObjectCopyWith<$Res>(_self.object, (value) {
    return _then(_self.copyWith(object: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class WireDelivered extends WireActivity {
  const WireDelivered({@JsonKey(name: '@context') this.context = ecpJsonLdContext, @UriConverter() this.id, @UriConverter() required final  List<Uri> to, @UriConverter() required this.object, @UriConverter() required this.actor, final  String? $type}): _to = to,$type = $type ?? 'Delivered',super._();
  factory WireDelivered.fromJson(Map<String, dynamic> json) => _$WireDeliveredFromJson(json);

@override@JsonKey(name: '@context') final  Object? context;
@override@UriConverter() final  Uri? id;
 final  List<Uri> _to;
@override@UriConverter() List<Uri> get to {
  if (_to is EqualUnmodifiableListView) return _to;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_to);
}

@UriConverter() final  Uri object;
@override@UriConverter() final  Uri actor;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireDeliveredCopyWith<WireDelivered> get copyWith => _$WireDeliveredCopyWithImpl<WireDelivered>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WireDeliveredToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireDelivered&&const DeepCollectionEquality().equals(other.context, context)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._to, _to)&&(identical(other.object, object) || other.object == object)&&(identical(other.actor, actor) || other.actor == actor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(context),id,const DeepCollectionEquality().hash(_to),object,actor);

@override
String toString() {
  return 'WireActivity.wireDelivered(context: $context, id: $id, to: $to, object: $object, actor: $actor)';
}


}

/// @nodoc
abstract mixin class $WireDeliveredCopyWith<$Res> implements $WireActivityCopyWith<$Res> {
  factory $WireDeliveredCopyWith(WireDelivered value, $Res Function(WireDelivered) _then) = _$WireDeliveredCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '@context') Object? context,@UriConverter() Uri? id,@UriConverter() List<Uri> to,@UriConverter() Uri object,@UriConverter() Uri actor
});




}
/// @nodoc
class _$WireDeliveredCopyWithImpl<$Res>
    implements $WireDeliveredCopyWith<$Res> {
  _$WireDeliveredCopyWithImpl(this._self, this._then);

  final WireDelivered _self;
  final $Res Function(WireDelivered) _then;

/// Create a copy of WireActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? context = freezed,Object? id = freezed,Object? to = null,Object? object = null,Object? actor = null,}) {
  return _then(WireDelivered(
context: freezed == context ? _self.context : context ,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as Uri?,to: null == to ? _self._to : to // ignore: cast_nullable_to_non_nullable
as List<Uri>,object: null == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as Uri,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}


}

// dart format on
