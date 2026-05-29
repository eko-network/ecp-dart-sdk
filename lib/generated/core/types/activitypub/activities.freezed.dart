// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../core/types/activitypub/activities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Activity _$ActivityFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'Typing':
          return Typing.fromJson(
            json
          );
                case 'Create':
          return Create.fromJson(
            json
          );
                case 'Update':
          return Update.fromJson(
            json
          );
                case 'Delete':
          return Delete.fromJson(
            json
          );
                case 'Delivered':
          return Delivered.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'Activity',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$Activity {



  /// Serializes this Activity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Activity);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Activity()';
}


}

/// @nodoc
class $ActivityCopyWith<$Res>  {
$ActivityCopyWith(Activity _, $Res Function(Activity) __);
}


/// Adds pattern-matching-related methods to [Activity].
extension ActivityPatterns on Activity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Typing value)?  typing,TResult Function( Create value)?  create,TResult Function( Update value)?  update,TResult Function( Delete value)?  delete,TResult Function( Delivered value)?  delivered,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Typing() when typing != null:
return typing(_that);case Create() when create != null:
return create(_that);case Update() when update != null:
return update(_that);case Delete() when delete != null:
return delete(_that);case Delivered() when delivered != null:
return delivered(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Typing value)  typing,required TResult Function( Create value)  create,required TResult Function( Update value)  update,required TResult Function( Delete value)  delete,required TResult Function( Delivered value)  delivered,}){
final _that = this;
switch (_that) {
case Typing():
return typing(_that);case Create():
return create(_that);case Update():
return update(_that);case Delete():
return delete(_that);case Delivered():
return delivered(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Typing value)?  typing,TResult? Function( Create value)?  create,TResult? Function( Update value)?  update,TResult? Function( Delete value)?  delete,TResult? Function( Delivered value)?  delivered,}){
final _that = this;
switch (_that) {
case Typing() when typing != null:
return typing(_that);case Create() when create != null:
return create(_that);case Update() when update != null:
return update(_that);case Delete() when delete != null:
return delete(_that);case Delivered() when delivered != null:
return delivered(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  typing,TResult Function(@InternalIdConverter()  InternalId id,  ActivityPubObject object)?  create,TResult Function(@InternalIdConverter()  InternalId id,  ActivityPubObject object)?  update,TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  dynamic object)?  delete,TResult Function(@InternalIdConverter()  InternalId id, @UriConverter()  Uri object)?  delivered,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Typing() when typing != null:
return typing();case Create() when create != null:
return create(_that.id,_that.object);case Update() when update != null:
return update(_that.id,_that.object);case Delete() when delete != null:
return delete(_that.id,_that.object);case Delivered() when delivered != null:
return delivered(_that.id,_that.object);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  typing,required TResult Function(@InternalIdConverter()  InternalId id,  ActivityPubObject object)  create,required TResult Function(@InternalIdConverter()  InternalId id,  ActivityPubObject object)  update,required TResult Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  dynamic object)  delete,required TResult Function(@InternalIdConverter()  InternalId id, @UriConverter()  Uri object)  delivered,}) {final _that = this;
switch (_that) {
case Typing():
return typing();case Create():
return create(_that.id,_that.object);case Update():
return update(_that.id,_that.object);case Delete():
return delete(_that.id,_that.object);case Delivered():
return delivered(_that.id,_that.object);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  typing,TResult? Function(@InternalIdConverter()  InternalId id,  ActivityPubObject object)?  create,TResult? Function(@InternalIdConverter()  InternalId id,  ActivityPubObject object)?  update,TResult? Function(@InternalIdConverter()  InternalId id, @InternalIdConverter()  dynamic object)?  delete,TResult? Function(@InternalIdConverter()  InternalId id, @UriConverter()  Uri object)?  delivered,}) {final _that = this;
switch (_that) {
case Typing() when typing != null:
return typing();case Create() when create != null:
return create(_that.id,_that.object);case Update() when update != null:
return update(_that.id,_that.object);case Delete() when delete != null:
return delete(_that.id,_that.object);case Delivered() when delivered != null:
return delivered(_that.id,_that.object);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Typing extends Activity {
  const Typing({final  String? $type}): $type = $type ?? 'Typing',super._();
  factory Typing.fromJson(Map<String, dynamic> json) => _$TypingFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$TypingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Typing);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Activity.typing()';
}


}




/// @nodoc
@JsonSerializable()

class Create extends Activity {
  const Create({@InternalIdConverter() required this.id, required this.object, final  String? $type}): $type = $type ?? 'Create',super._();
  factory Create.fromJson(Map<String, dynamic> json) => _$CreateFromJson(json);

@InternalIdConverter() final  InternalId id;
 final  ActivityPubObject object;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateCopyWith<Create> get copyWith => _$CreateCopyWithImpl<Create>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Create&&(identical(other.id, id) || other.id == id)&&(identical(other.object, object) || other.object == object));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,object);

@override
String toString() {
  return 'Activity.create(id: $id, object: $object)';
}


}

/// @nodoc
abstract mixin class $CreateCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory $CreateCopyWith(Create value, $Res Function(Create) _then) = _$CreateCopyWithImpl;
@useResult
$Res call({
@InternalIdConverter() InternalId id, ActivityPubObject object
});


$ActivityPubObjectCopyWith<$Res> get object;

}
/// @nodoc
class _$CreateCopyWithImpl<$Res>
    implements $CreateCopyWith<$Res> {
  _$CreateCopyWithImpl(this._self, this._then);

  final Create _self;
  final $Res Function(Create) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? object = null,}) {
  return _then(Create(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,object: null == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as ActivityPubObject,
  ));
}

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityPubObjectCopyWith<$Res> get object {
  
  return $ActivityPubObjectCopyWith<$Res>(_self.object, (value) {
    return _then(_self.copyWith(object: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class Update extends Activity {
  const Update({@InternalIdConverter() required this.id, required this.object, final  String? $type}): $type = $type ?? 'Update',super._();
  factory Update.fromJson(Map<String, dynamic> json) => _$UpdateFromJson(json);

@InternalIdConverter() final  InternalId id;
 final  ActivityPubObject object;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateCopyWith<Update> get copyWith => _$UpdateCopyWithImpl<Update>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Update&&(identical(other.id, id) || other.id == id)&&(identical(other.object, object) || other.object == object));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,object);

@override
String toString() {
  return 'Activity.update(id: $id, object: $object)';
}


}

/// @nodoc
abstract mixin class $UpdateCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory $UpdateCopyWith(Update value, $Res Function(Update) _then) = _$UpdateCopyWithImpl;
@useResult
$Res call({
@InternalIdConverter() InternalId id, ActivityPubObject object
});


$ActivityPubObjectCopyWith<$Res> get object;

}
/// @nodoc
class _$UpdateCopyWithImpl<$Res>
    implements $UpdateCopyWith<$Res> {
  _$UpdateCopyWithImpl(this._self, this._then);

  final Update _self;
  final $Res Function(Update) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? object = null,}) {
  return _then(Update(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,object: null == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as ActivityPubObject,
  ));
}

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityPubObjectCopyWith<$Res> get object {
  
  return $ActivityPubObjectCopyWith<$Res>(_self.object, (value) {
    return _then(_self.copyWith(object: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class Delete extends Activity {
  const Delete({@InternalIdConverter() required this.id, @InternalIdConverter() required this.object, final  String? $type}): $type = $type ?? 'Delete',super._();
  factory Delete.fromJson(Map<String, dynamic> json) => _$DeleteFromJson(json);

@InternalIdConverter() final  InternalId id;
@InternalIdConverter() final  dynamic object;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteCopyWith<Delete> get copyWith => _$DeleteCopyWithImpl<Delete>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeleteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Delete&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.object, object));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(object));

@override
String toString() {
  return 'Activity.delete(id: $id, object: $object)';
}


}

/// @nodoc
abstract mixin class $DeleteCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory $DeleteCopyWith(Delete value, $Res Function(Delete) _then) = _$DeleteCopyWithImpl;
@useResult
$Res call({
@InternalIdConverter() InternalId id,@InternalIdConverter() dynamic object
});




}
/// @nodoc
class _$DeleteCopyWithImpl<$Res>
    implements $DeleteCopyWith<$Res> {
  _$DeleteCopyWithImpl(this._self, this._then);

  final Delete _self;
  final $Res Function(Delete) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? object = freezed,}) {
  return _then(Delete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,object: freezed == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Delivered extends Activity {
  const Delivered({@InternalIdConverter() required this.id, @UriConverter() required this.object, final  String? $type}): $type = $type ?? 'Delivered',super._();
  factory Delivered.fromJson(Map<String, dynamic> json) => _$DeliveredFromJson(json);

@InternalIdConverter() final  InternalId id;
@UriConverter() final  Uri object;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveredCopyWith<Delivered> get copyWith => _$DeliveredCopyWithImpl<Delivered>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeliveredToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Delivered&&(identical(other.id, id) || other.id == id)&&(identical(other.object, object) || other.object == object));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,object);

@override
String toString() {
  return 'Activity.delivered(id: $id, object: $object)';
}


}

/// @nodoc
abstract mixin class $DeliveredCopyWith<$Res> implements $ActivityCopyWith<$Res> {
  factory $DeliveredCopyWith(Delivered value, $Res Function(Delivered) _then) = _$DeliveredCopyWithImpl;
@useResult
$Res call({
@InternalIdConverter() InternalId id,@UriConverter() Uri object
});




}
/// @nodoc
class _$DeliveredCopyWithImpl<$Res>
    implements $DeliveredCopyWith<$Res> {
  _$DeliveredCopyWithImpl(this._self, this._then);

  final Delivered _self;
  final $Res Function(Delivered) _then;

/// Create a copy of Activity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? object = null,}) {
  return _then(Delivered(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as InternalId,object: null == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as Uri,
  ));
}


}

// dart format on
