// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlankaUser {

 String get id; String get name; String? get username; String? get email; Map<String, dynamic>? get avatar;
/// Create a copy of PlankaUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaUserCopyWith<PlankaUser> get copyWith => _$PlankaUserCopyWithImpl<PlankaUser>(this as PlankaUser, _$identity);

  /// Serializes this PlankaUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.avatar, avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,const DeepCollectionEquality().hash(avatar));

@override
String toString() {
  return 'PlankaUser(id: $id, name: $name, username: $username, email: $email, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $PlankaUserCopyWith<$Res>  {
  factory $PlankaUserCopyWith(PlankaUser value, $Res Function(PlankaUser) _then) = _$PlankaUserCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? username, String? email, Map<String, dynamic>? avatar
});




}
/// @nodoc
class _$PlankaUserCopyWithImpl<$Res>
    implements $PlankaUserCopyWith<$Res> {
  _$PlankaUserCopyWithImpl(this._self, this._then);

  final PlankaUser _self;
  final $Res Function(PlankaUser) _then;

/// Create a copy of PlankaUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? username = freezed,Object? email = freezed,Object? avatar = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaUser].
extension PlankaUserPatterns on PlankaUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaUser() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaUser value)  $default,){
final _that = this;
switch (_that) {
case _PlankaUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaUser value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaUser() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? username,  String? email,  Map<String, dynamic>? avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaUser() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? username,  String? email,  Map<String, dynamic>? avatar)  $default,) {final _that = this;
switch (_that) {
case _PlankaUser():
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? username,  String? email,  Map<String, dynamic>? avatar)?  $default,) {final _that = this;
switch (_that) {
case _PlankaUser() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaUser implements PlankaUser {
  const _PlankaUser({required this.id, required this.name, this.username, this.email, final  Map<String, dynamic>? avatar}): _avatar = avatar;
  factory _PlankaUser.fromJson(Map<String, dynamic> json) => _$PlankaUserFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? username;
@override final  String? email;
 final  Map<String, dynamic>? _avatar;
@override Map<String, dynamic>? get avatar {
  final value = _avatar;
  if (value == null) return null;
  if (_avatar is EqualUnmodifiableMapView) return _avatar;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PlankaUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaUserCopyWith<_PlankaUser> get copyWith => __$PlankaUserCopyWithImpl<_PlankaUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._avatar, _avatar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,const DeepCollectionEquality().hash(_avatar));

@override
String toString() {
  return 'PlankaUser(id: $id, name: $name, username: $username, email: $email, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$PlankaUserCopyWith<$Res> implements $PlankaUserCopyWith<$Res> {
  factory _$PlankaUserCopyWith(_PlankaUser value, $Res Function(_PlankaUser) _then) = __$PlankaUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? username, String? email, Map<String, dynamic>? avatar
});




}
/// @nodoc
class __$PlankaUserCopyWithImpl<$Res>
    implements _$PlankaUserCopyWith<$Res> {
  __$PlankaUserCopyWithImpl(this._self, this._then);

  final _PlankaUser _self;
  final $Res Function(_PlankaUser) _then;

/// Create a copy of PlankaUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? username = freezed,Object? email = freezed,Object? avatar = freezed,}) {
  return _then(_PlankaUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self._avatar : avatar // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$PlankaProject {

 String get id; String get name;
/// Create a copy of PlankaProject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaProjectCopyWith<PlankaProject> get copyWith => _$PlankaProjectCopyWithImpl<PlankaProject>(this as PlankaProject, _$identity);

  /// Serializes this PlankaProject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaProject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'PlankaProject(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $PlankaProjectCopyWith<$Res>  {
  factory $PlankaProjectCopyWith(PlankaProject value, $Res Function(PlankaProject) _then) = _$PlankaProjectCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$PlankaProjectCopyWithImpl<$Res>
    implements $PlankaProjectCopyWith<$Res> {
  _$PlankaProjectCopyWithImpl(this._self, this._then);

  final PlankaProject _self;
  final $Res Function(PlankaProject) _then;

/// Create a copy of PlankaProject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaProject].
extension PlankaProjectPatterns on PlankaProject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaProject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaProject() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaProject value)  $default,){
final _that = this;
switch (_that) {
case _PlankaProject():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaProject value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaProject() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaProject() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _PlankaProject():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _PlankaProject() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaProject implements PlankaProject {
  const _PlankaProject({required this.id, required this.name});
  factory _PlankaProject.fromJson(Map<String, dynamic> json) => _$PlankaProjectFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of PlankaProject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaProjectCopyWith<_PlankaProject> get copyWith => __$PlankaProjectCopyWithImpl<_PlankaProject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaProjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaProject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'PlankaProject(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PlankaProjectCopyWith<$Res> implements $PlankaProjectCopyWith<$Res> {
  factory _$PlankaProjectCopyWith(_PlankaProject value, $Res Function(_PlankaProject) _then) = __$PlankaProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$PlankaProjectCopyWithImpl<$Res>
    implements _$PlankaProjectCopyWith<$Res> {
  __$PlankaProjectCopyWithImpl(this._self, this._then);

  final _PlankaProject _self;
  final $Res Function(_PlankaProject) _then;

/// Create a copy of PlankaProject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_PlankaProject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlankaBoard {

 String get id; String get projectId; String get name;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaBoard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaBoardCopyWith<PlankaBoard> get copyWith => _$PlankaBoardCopyWithImpl<PlankaBoard>(this as PlankaBoard, _$identity);

  /// Serializes this PlankaBoard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaBoard&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,name,position);

@override
String toString() {
  return 'PlankaBoard(id: $id, projectId: $projectId, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaBoardCopyWith<$Res>  {
  factory $PlankaBoardCopyWith(PlankaBoard value, $Res Function(PlankaBoard) _then) = _$PlankaBoardCopyWithImpl;
@useResult
$Res call({
 String id, String projectId, String name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaBoardCopyWithImpl<$Res>
    implements $PlankaBoardCopyWith<$Res> {
  _$PlankaBoardCopyWithImpl(this._self, this._then);

  final PlankaBoard _self;
  final $Res Function(PlankaBoard) _then;

/// Create a copy of PlankaBoard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? name = null,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaBoard].
extension PlankaBoardPatterns on PlankaBoard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaBoard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaBoard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaBoard value)  $default,){
final _that = this;
switch (_that) {
case _PlankaBoard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaBoard value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaBoard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectId,  String name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaBoard() when $default != null:
return $default(_that.id,_that.projectId,_that.name,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectId,  String name, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaBoard():
return $default(_that.id,_that.projectId,_that.name,_that.position);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectId,  String name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaBoard() when $default != null:
return $default(_that.id,_that.projectId,_that.name,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaBoard implements PlankaBoard {
  const _PlankaBoard({required this.id, required this.projectId, required this.name, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaBoard.fromJson(Map<String, dynamic> json) => _$PlankaBoardFromJson(json);

@override final  String id;
@override final  String projectId;
@override final  String name;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaBoard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaBoardCopyWith<_PlankaBoard> get copyWith => __$PlankaBoardCopyWithImpl<_PlankaBoard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaBoardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaBoard&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,name,position);

@override
String toString() {
  return 'PlankaBoard(id: $id, projectId: $projectId, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaBoardCopyWith<$Res> implements $PlankaBoardCopyWith<$Res> {
  factory _$PlankaBoardCopyWith(_PlankaBoard value, $Res Function(_PlankaBoard) _then) = __$PlankaBoardCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectId, String name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaBoardCopyWithImpl<$Res>
    implements _$PlankaBoardCopyWith<$Res> {
  __$PlankaBoardCopyWithImpl(this._self, this._then);

  final _PlankaBoard _self;
  final $Res Function(_PlankaBoard) _then;

/// Create a copy of PlankaBoard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? name = null,Object? position = freezed,}) {
  return _then(_PlankaBoard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlankaList {

 String get id; String get boardId; String get type; String? get name;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaListCopyWith<PlankaList> get copyWith => _$PlankaListCopyWithImpl<PlankaList>(this as PlankaList, _$identity);

  /// Serializes this PlankaList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaList&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,type,name,position);

@override
String toString() {
  return 'PlankaList(id: $id, boardId: $boardId, type: $type, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaListCopyWith<$Res>  {
  factory $PlankaListCopyWith(PlankaList value, $Res Function(PlankaList) _then) = _$PlankaListCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String type, String? name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaListCopyWithImpl<$Res>
    implements $PlankaListCopyWith<$Res> {
  _$PlankaListCopyWithImpl(this._self, this._then);

  final PlankaList _self;
  final $Res Function(PlankaList) _then;

/// Create a copy of PlankaList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? type = null,Object? name = freezed,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaList].
extension PlankaListPatterns on PlankaList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaList() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaList value)  $default,){
final _that = this;
switch (_that) {
case _PlankaList():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaList value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaList() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String type,  String? name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaList() when $default != null:
return $default(_that.id,_that.boardId,_that.type,_that.name,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String type,  String? name, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaList():
return $default(_that.id,_that.boardId,_that.type,_that.name,_that.position);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String type,  String? name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaList() when $default != null:
return $default(_that.id,_that.boardId,_that.type,_that.name,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaList implements PlankaList {
  const _PlankaList({required this.id, required this.boardId, required this.type, this.name, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaList.fromJson(Map<String, dynamic> json) => _$PlankaListFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String type;
@override final  String? name;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaListCopyWith<_PlankaList> get copyWith => __$PlankaListCopyWithImpl<_PlankaList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaList&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,type,name,position);

@override
String toString() {
  return 'PlankaList(id: $id, boardId: $boardId, type: $type, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaListCopyWith<$Res> implements $PlankaListCopyWith<$Res> {
  factory _$PlankaListCopyWith(_PlankaList value, $Res Function(_PlankaList) _then) = __$PlankaListCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String type, String? name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaListCopyWithImpl<$Res>
    implements _$PlankaListCopyWith<$Res> {
  __$PlankaListCopyWithImpl(this._self, this._then);

  final _PlankaList _self;
  final $Res Function(_PlankaList) _then;

/// Create a copy of PlankaList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? type = null,Object? name = freezed,Object? position = freezed,}) {
  return _then(_PlankaList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlankaCard {

 String get id; String get boardId; String get listId; String get type; String get name;@JsonKey(fromJson: _toDouble) double? get position; String? get description; DateTime? get dueDate; bool? get isDueCompleted; String? get coverAttachmentId; DateTime? get createdAt;
/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCardCopyWith<PlankaCard> get copyWith => _$PlankaCardCopyWithImpl<PlankaCard>(this as PlankaCard, _$identity);

  /// Serializes this PlankaCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCard&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isDueCompleted, isDueCompleted) || other.isDueCompleted == isDueCompleted)&&(identical(other.coverAttachmentId, coverAttachmentId) || other.coverAttachmentId == coverAttachmentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,listId,type,name,position,description,dueDate,isDueCompleted,coverAttachmentId,createdAt);

@override
String toString() {
  return 'PlankaCard(id: $id, boardId: $boardId, listId: $listId, type: $type, name: $name, position: $position, description: $description, dueDate: $dueDate, isDueCompleted: $isDueCompleted, coverAttachmentId: $coverAttachmentId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlankaCardCopyWith<$Res>  {
  factory $PlankaCardCopyWith(PlankaCard value, $Res Function(PlankaCard) _then) = _$PlankaCardCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String listId, String type, String name,@JsonKey(fromJson: _toDouble) double? position, String? description, DateTime? dueDate, bool? isDueCompleted, String? coverAttachmentId, DateTime? createdAt
});




}
/// @nodoc
class _$PlankaCardCopyWithImpl<$Res>
    implements $PlankaCardCopyWith<$Res> {
  _$PlankaCardCopyWithImpl(this._self, this._then);

  final PlankaCard _self;
  final $Res Function(PlankaCard) _then;

/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? listId = null,Object? type = null,Object? name = null,Object? position = freezed,Object? description = freezed,Object? dueDate = freezed,Object? isDueCompleted = freezed,Object? coverAttachmentId = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isDueCompleted: freezed == isDueCompleted ? _self.isDueCompleted : isDueCompleted // ignore: cast_nullable_to_non_nullable
as bool?,coverAttachmentId: freezed == coverAttachmentId ? _self.coverAttachmentId : coverAttachmentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaCard].
extension PlankaCardPatterns on PlankaCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaCard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaCard value)  $default,){
final _that = this;
switch (_that) {
case _PlankaCard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaCard value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaCard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String listId,  String type,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? description,  DateTime? dueDate,  bool? isDueCompleted,  String? coverAttachmentId,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaCard() when $default != null:
return $default(_that.id,_that.boardId,_that.listId,_that.type,_that.name,_that.position,_that.description,_that.dueDate,_that.isDueCompleted,_that.coverAttachmentId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String listId,  String type,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? description,  DateTime? dueDate,  bool? isDueCompleted,  String? coverAttachmentId,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PlankaCard():
return $default(_that.id,_that.boardId,_that.listId,_that.type,_that.name,_that.position,_that.description,_that.dueDate,_that.isDueCompleted,_that.coverAttachmentId,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String listId,  String type,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? description,  DateTime? dueDate,  bool? isDueCompleted,  String? coverAttachmentId,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PlankaCard() when $default != null:
return $default(_that.id,_that.boardId,_that.listId,_that.type,_that.name,_that.position,_that.description,_that.dueDate,_that.isDueCompleted,_that.coverAttachmentId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCard implements PlankaCard {
  const _PlankaCard({required this.id, required this.boardId, required this.listId, required this.type, required this.name, @JsonKey(fromJson: _toDouble) this.position, this.description, this.dueDate, this.isDueCompleted, this.coverAttachmentId, this.createdAt});
  factory _PlankaCard.fromJson(Map<String, dynamic> json) => _$PlankaCardFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String listId;
@override final  String type;
@override final  String name;
@override@JsonKey(fromJson: _toDouble) final  double? position;
@override final  String? description;
@override final  DateTime? dueDate;
@override final  bool? isDueCompleted;
@override final  String? coverAttachmentId;
@override final  DateTime? createdAt;

/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCardCopyWith<_PlankaCard> get copyWith => __$PlankaCardCopyWithImpl<_PlankaCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCard&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isDueCompleted, isDueCompleted) || other.isDueCompleted == isDueCompleted)&&(identical(other.coverAttachmentId, coverAttachmentId) || other.coverAttachmentId == coverAttachmentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,listId,type,name,position,description,dueDate,isDueCompleted,coverAttachmentId,createdAt);

@override
String toString() {
  return 'PlankaCard(id: $id, boardId: $boardId, listId: $listId, type: $type, name: $name, position: $position, description: $description, dueDate: $dueDate, isDueCompleted: $isDueCompleted, coverAttachmentId: $coverAttachmentId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlankaCardCopyWith<$Res> implements $PlankaCardCopyWith<$Res> {
  factory _$PlankaCardCopyWith(_PlankaCard value, $Res Function(_PlankaCard) _then) = __$PlankaCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String listId, String type, String name,@JsonKey(fromJson: _toDouble) double? position, String? description, DateTime? dueDate, bool? isDueCompleted, String? coverAttachmentId, DateTime? createdAt
});




}
/// @nodoc
class __$PlankaCardCopyWithImpl<$Res>
    implements _$PlankaCardCopyWith<$Res> {
  __$PlankaCardCopyWithImpl(this._self, this._then);

  final _PlankaCard _self;
  final $Res Function(_PlankaCard) _then;

/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? listId = null,Object? type = null,Object? name = null,Object? position = freezed,Object? description = freezed,Object? dueDate = freezed,Object? isDueCompleted = freezed,Object? coverAttachmentId = freezed,Object? createdAt = freezed,}) {
  return _then(_PlankaCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isDueCompleted: freezed == isDueCompleted ? _self.isDueCompleted : isDueCompleted // ignore: cast_nullable_to_non_nullable
as bool?,coverAttachmentId: freezed == coverAttachmentId ? _self.coverAttachmentId : coverAttachmentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PlankaLabel {

 String get id; String get boardId; String get color; String? get name;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaLabel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaLabelCopyWith<PlankaLabel> get copyWith => _$PlankaLabelCopyWithImpl<PlankaLabel>(this as PlankaLabel, _$identity);

  /// Serializes this PlankaLabel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.color, color) || other.color == color)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,color,name,position);

@override
String toString() {
  return 'PlankaLabel(id: $id, boardId: $boardId, color: $color, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaLabelCopyWith<$Res>  {
  factory $PlankaLabelCopyWith(PlankaLabel value, $Res Function(PlankaLabel) _then) = _$PlankaLabelCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String color, String? name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaLabelCopyWithImpl<$Res>
    implements $PlankaLabelCopyWith<$Res> {
  _$PlankaLabelCopyWithImpl(this._self, this._then);

  final PlankaLabel _self;
  final $Res Function(PlankaLabel) _then;

/// Create a copy of PlankaLabel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? color = null,Object? name = freezed,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaLabel].
extension PlankaLabelPatterns on PlankaLabel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaLabel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaLabel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaLabel value)  $default,){
final _that = this;
switch (_that) {
case _PlankaLabel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaLabel value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaLabel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String color,  String? name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaLabel() when $default != null:
return $default(_that.id,_that.boardId,_that.color,_that.name,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String color,  String? name, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaLabel():
return $default(_that.id,_that.boardId,_that.color,_that.name,_that.position);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String color,  String? name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaLabel() when $default != null:
return $default(_that.id,_that.boardId,_that.color,_that.name,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaLabel implements PlankaLabel {
  const _PlankaLabel({required this.id, required this.boardId, required this.color, this.name, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaLabel.fromJson(Map<String, dynamic> json) => _$PlankaLabelFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String color;
@override final  String? name;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaLabel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaLabelCopyWith<_PlankaLabel> get copyWith => __$PlankaLabelCopyWithImpl<_PlankaLabel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaLabelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.color, color) || other.color == color)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,color,name,position);

@override
String toString() {
  return 'PlankaLabel(id: $id, boardId: $boardId, color: $color, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaLabelCopyWith<$Res> implements $PlankaLabelCopyWith<$Res> {
  factory _$PlankaLabelCopyWith(_PlankaLabel value, $Res Function(_PlankaLabel) _then) = __$PlankaLabelCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String color, String? name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaLabelCopyWithImpl<$Res>
    implements _$PlankaLabelCopyWith<$Res> {
  __$PlankaLabelCopyWithImpl(this._self, this._then);

  final _PlankaLabel _self;
  final $Res Function(_PlankaLabel) _then;

/// Create a copy of PlankaLabel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? color = null,Object? name = freezed,Object? position = freezed,}) {
  return _then(_PlankaLabel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$CardLabel {

 String get id; String get cardId; String get labelId;
/// Create a copy of CardLabel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardLabelCopyWith<CardLabel> get copyWith => _$CardLabelCopyWithImpl<CardLabel>(this as CardLabel, _$identity);

  /// Serializes this CardLabel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.labelId, labelId) || other.labelId == labelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,labelId);

@override
String toString() {
  return 'CardLabel(id: $id, cardId: $cardId, labelId: $labelId)';
}


}

/// @nodoc
abstract mixin class $CardLabelCopyWith<$Res>  {
  factory $CardLabelCopyWith(CardLabel value, $Res Function(CardLabel) _then) = _$CardLabelCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String labelId
});




}
/// @nodoc
class _$CardLabelCopyWithImpl<$Res>
    implements $CardLabelCopyWith<$Res> {
  _$CardLabelCopyWithImpl(this._self, this._then);

  final CardLabel _self;
  final $Res Function(CardLabel) _then;

/// Create a copy of CardLabel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? labelId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,labelId: null == labelId ? _self.labelId : labelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CardLabel].
extension CardLabelPatterns on CardLabel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardLabel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardLabel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardLabel value)  $default,){
final _that = this;
switch (_that) {
case _CardLabel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardLabel value)?  $default,){
final _that = this;
switch (_that) {
case _CardLabel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String labelId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardLabel() when $default != null:
return $default(_that.id,_that.cardId,_that.labelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String labelId)  $default,) {final _that = this;
switch (_that) {
case _CardLabel():
return $default(_that.id,_that.cardId,_that.labelId);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String labelId)?  $default,) {final _that = this;
switch (_that) {
case _CardLabel() when $default != null:
return $default(_that.id,_that.cardId,_that.labelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardLabel implements CardLabel {
  const _CardLabel({required this.id, required this.cardId, required this.labelId});
  factory _CardLabel.fromJson(Map<String, dynamic> json) => _$CardLabelFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String labelId;

/// Create a copy of CardLabel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardLabelCopyWith<_CardLabel> get copyWith => __$CardLabelCopyWithImpl<_CardLabel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardLabelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.labelId, labelId) || other.labelId == labelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,labelId);

@override
String toString() {
  return 'CardLabel(id: $id, cardId: $cardId, labelId: $labelId)';
}


}

/// @nodoc
abstract mixin class _$CardLabelCopyWith<$Res> implements $CardLabelCopyWith<$Res> {
  factory _$CardLabelCopyWith(_CardLabel value, $Res Function(_CardLabel) _then) = __$CardLabelCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String labelId
});




}
/// @nodoc
class __$CardLabelCopyWithImpl<$Res>
    implements _$CardLabelCopyWith<$Res> {
  __$CardLabelCopyWithImpl(this._self, this._then);

  final _CardLabel _self;
  final $Res Function(_CardLabel) _then;

/// Create a copy of CardLabel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? labelId = null,}) {
  return _then(_CardLabel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,labelId: null == labelId ? _self.labelId : labelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CardMembership {

 String get id; String get cardId; String get userId;
/// Create a copy of CardMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardMembershipCopyWith<CardMembership> get copyWith => _$CardMembershipCopyWithImpl<CardMembership>(this as CardMembership, _$identity);

  /// Serializes this CardMembership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,userId);

@override
String toString() {
  return 'CardMembership(id: $id, cardId: $cardId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class $CardMembershipCopyWith<$Res>  {
  factory $CardMembershipCopyWith(CardMembership value, $Res Function(CardMembership) _then) = _$CardMembershipCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String userId
});




}
/// @nodoc
class _$CardMembershipCopyWithImpl<$Res>
    implements $CardMembershipCopyWith<$Res> {
  _$CardMembershipCopyWithImpl(this._self, this._then);

  final CardMembership _self;
  final $Res Function(CardMembership) _then;

/// Create a copy of CardMembership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? userId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CardMembership].
extension CardMembershipPatterns on CardMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardMembership() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardMembership value)  $default,){
final _that = this;
switch (_that) {
case _CardMembership():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardMembership value)?  $default,){
final _that = this;
switch (_that) {
case _CardMembership() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String userId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardMembership() when $default != null:
return $default(_that.id,_that.cardId,_that.userId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String userId)  $default,) {final _that = this;
switch (_that) {
case _CardMembership():
return $default(_that.id,_that.cardId,_that.userId);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String userId)?  $default,) {final _that = this;
switch (_that) {
case _CardMembership() when $default != null:
return $default(_that.id,_that.cardId,_that.userId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardMembership implements CardMembership {
  const _CardMembership({required this.id, required this.cardId, required this.userId});
  factory _CardMembership.fromJson(Map<String, dynamic> json) => _$CardMembershipFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String userId;

/// Create a copy of CardMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardMembershipCopyWith<_CardMembership> get copyWith => __$CardMembershipCopyWithImpl<_CardMembership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardMembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,userId);

@override
String toString() {
  return 'CardMembership(id: $id, cardId: $cardId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class _$CardMembershipCopyWith<$Res> implements $CardMembershipCopyWith<$Res> {
  factory _$CardMembershipCopyWith(_CardMembership value, $Res Function(_CardMembership) _then) = __$CardMembershipCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String userId
});




}
/// @nodoc
class __$CardMembershipCopyWithImpl<$Res>
    implements _$CardMembershipCopyWith<$Res> {
  __$CardMembershipCopyWithImpl(this._self, this._then);

  final _CardMembership _self;
  final $Res Function(_CardMembership) _then;

/// Create a copy of CardMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? userId = null,}) {
  return _then(_CardMembership(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BoardMembership {

 String get id; String get boardId; String get userId; String get role;
/// Create a copy of BoardMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardMembershipCopyWith<BoardMembership> get copyWith => _$BoardMembershipCopyWithImpl<BoardMembership>(this as BoardMembership, _$identity);

  /// Serializes this BoardMembership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,userId,role);

@override
String toString() {
  return 'BoardMembership(id: $id, boardId: $boardId, userId: $userId, role: $role)';
}


}

/// @nodoc
abstract mixin class $BoardMembershipCopyWith<$Res>  {
  factory $BoardMembershipCopyWith(BoardMembership value, $Res Function(BoardMembership) _then) = _$BoardMembershipCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String userId, String role
});




}
/// @nodoc
class _$BoardMembershipCopyWithImpl<$Res>
    implements $BoardMembershipCopyWith<$Res> {
  _$BoardMembershipCopyWithImpl(this._self, this._then);

  final BoardMembership _self;
  final $Res Function(BoardMembership) _then;

/// Create a copy of BoardMembership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? userId = null,Object? role = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardMembership].
extension BoardMembershipPatterns on BoardMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardMembership() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardMembership value)  $default,){
final _that = this;
switch (_that) {
case _BoardMembership():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardMembership value)?  $default,){
final _that = this;
switch (_that) {
case _BoardMembership() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String userId,  String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardMembership() when $default != null:
return $default(_that.id,_that.boardId,_that.userId,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String userId,  String role)  $default,) {final _that = this;
switch (_that) {
case _BoardMembership():
return $default(_that.id,_that.boardId,_that.userId,_that.role);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String userId,  String role)?  $default,) {final _that = this;
switch (_that) {
case _BoardMembership() when $default != null:
return $default(_that.id,_that.boardId,_that.userId,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardMembership implements BoardMembership {
  const _BoardMembership({required this.id, required this.boardId, required this.userId, required this.role});
  factory _BoardMembership.fromJson(Map<String, dynamic> json) => _$BoardMembershipFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String userId;
@override final  String role;

/// Create a copy of BoardMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardMembershipCopyWith<_BoardMembership> get copyWith => __$BoardMembershipCopyWithImpl<_BoardMembership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardMembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,userId,role);

@override
String toString() {
  return 'BoardMembership(id: $id, boardId: $boardId, userId: $userId, role: $role)';
}


}

/// @nodoc
abstract mixin class _$BoardMembershipCopyWith<$Res> implements $BoardMembershipCopyWith<$Res> {
  factory _$BoardMembershipCopyWith(_BoardMembership value, $Res Function(_BoardMembership) _then) = __$BoardMembershipCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String userId, String role
});




}
/// @nodoc
class __$BoardMembershipCopyWithImpl<$Res>
    implements _$BoardMembershipCopyWith<$Res> {
  __$BoardMembershipCopyWithImpl(this._self, this._then);

  final _BoardMembership _self;
  final $Res Function(_BoardMembership) _then;

/// Create a copy of BoardMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? userId = null,Object? role = null,}) {
  return _then(_BoardMembership(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlankaTaskList {

 String get id; String get cardId; String get name;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaTaskList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaTaskListCopyWith<PlankaTaskList> get copyWith => _$PlankaTaskListCopyWithImpl<PlankaTaskList>(this as PlankaTaskList, _$identity);

  /// Serializes this PlankaTaskList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaTaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,name,position);

@override
String toString() {
  return 'PlankaTaskList(id: $id, cardId: $cardId, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaTaskListCopyWith<$Res>  {
  factory $PlankaTaskListCopyWith(PlankaTaskList value, $Res Function(PlankaTaskList) _then) = _$PlankaTaskListCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaTaskListCopyWithImpl<$Res>
    implements $PlankaTaskListCopyWith<$Res> {
  _$PlankaTaskListCopyWithImpl(this._self, this._then);

  final PlankaTaskList _self;
  final $Res Function(PlankaTaskList) _then;

/// Create a copy of PlankaTaskList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? name = null,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaTaskList].
extension PlankaTaskListPatterns on PlankaTaskList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaTaskList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaTaskList() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaTaskList value)  $default,){
final _that = this;
switch (_that) {
case _PlankaTaskList():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaTaskList value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaTaskList() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaTaskList() when $default != null:
return $default(_that.id,_that.cardId,_that.name,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String name, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaTaskList():
return $default(_that.id,_that.cardId,_that.name,_that.position);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String name, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaTaskList() when $default != null:
return $default(_that.id,_that.cardId,_that.name,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaTaskList implements PlankaTaskList {
  const _PlankaTaskList({required this.id, required this.cardId, required this.name, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaTaskList.fromJson(Map<String, dynamic> json) => _$PlankaTaskListFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String name;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaTaskList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaTaskListCopyWith<_PlankaTaskList> get copyWith => __$PlankaTaskListCopyWithImpl<_PlankaTaskList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaTaskListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaTaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,name,position);

@override
String toString() {
  return 'PlankaTaskList(id: $id, cardId: $cardId, name: $name, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaTaskListCopyWith<$Res> implements $PlankaTaskListCopyWith<$Res> {
  factory _$PlankaTaskListCopyWith(_PlankaTaskList value, $Res Function(_PlankaTaskList) _then) = __$PlankaTaskListCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String name,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaTaskListCopyWithImpl<$Res>
    implements _$PlankaTaskListCopyWith<$Res> {
  __$PlankaTaskListCopyWithImpl(this._self, this._then);

  final _PlankaTaskList _self;
  final $Res Function(_PlankaTaskList) _then;

/// Create a copy of PlankaTaskList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? name = null,Object? position = freezed,}) {
  return _then(_PlankaTaskList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlankaTask {

 String get id; String get taskListId; String get name; bool get isCompleted;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaTaskCopyWith<PlankaTask> get copyWith => _$PlankaTaskCopyWithImpl<PlankaTask>(this as PlankaTask, _$identity);

  /// Serializes this PlankaTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaTask&&(identical(other.id, id) || other.id == id)&&(identical(other.taskListId, taskListId) || other.taskListId == taskListId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskListId,name,isCompleted,position);

@override
String toString() {
  return 'PlankaTask(id: $id, taskListId: $taskListId, name: $name, isCompleted: $isCompleted, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaTaskCopyWith<$Res>  {
  factory $PlankaTaskCopyWith(PlankaTask value, $Res Function(PlankaTask) _then) = _$PlankaTaskCopyWithImpl;
@useResult
$Res call({
 String id, String taskListId, String name, bool isCompleted,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaTaskCopyWithImpl<$Res>
    implements $PlankaTaskCopyWith<$Res> {
  _$PlankaTaskCopyWithImpl(this._self, this._then);

  final PlankaTask _self;
  final $Res Function(PlankaTask) _then;

/// Create a copy of PlankaTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskListId = null,Object? name = null,Object? isCompleted = null,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskListId: null == taskListId ? _self.taskListId : taskListId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaTask].
extension PlankaTaskPatterns on PlankaTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaTask() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaTask value)  $default,){
final _that = this;
switch (_that) {
case _PlankaTask():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaTask value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaTask() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskListId,  String name,  bool isCompleted, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaTask() when $default != null:
return $default(_that.id,_that.taskListId,_that.name,_that.isCompleted,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskListId,  String name,  bool isCompleted, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaTask():
return $default(_that.id,_that.taskListId,_that.name,_that.isCompleted,_that.position);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskListId,  String name,  bool isCompleted, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaTask() when $default != null:
return $default(_that.id,_that.taskListId,_that.name,_that.isCompleted,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaTask implements PlankaTask {
  const _PlankaTask({required this.id, required this.taskListId, required this.name, required this.isCompleted, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaTask.fromJson(Map<String, dynamic> json) => _$PlankaTaskFromJson(json);

@override final  String id;
@override final  String taskListId;
@override final  String name;
@override final  bool isCompleted;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaTaskCopyWith<_PlankaTask> get copyWith => __$PlankaTaskCopyWithImpl<_PlankaTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaTask&&(identical(other.id, id) || other.id == id)&&(identical(other.taskListId, taskListId) || other.taskListId == taskListId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskListId,name,isCompleted,position);

@override
String toString() {
  return 'PlankaTask(id: $id, taskListId: $taskListId, name: $name, isCompleted: $isCompleted, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaTaskCopyWith<$Res> implements $PlankaTaskCopyWith<$Res> {
  factory _$PlankaTaskCopyWith(_PlankaTask value, $Res Function(_PlankaTask) _then) = __$PlankaTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskListId, String name, bool isCompleted,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaTaskCopyWithImpl<$Res>
    implements _$PlankaTaskCopyWith<$Res> {
  __$PlankaTaskCopyWithImpl(this._self, this._then);

  final _PlankaTask _self;
  final $Res Function(_PlankaTask) _then;

/// Create a copy of PlankaTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskListId = null,Object? name = null,Object? isCompleted = null,Object? position = freezed,}) {
  return _then(_PlankaTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskListId: null == taskListId ? _self.taskListId : taskListId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlankaComment {

 String get id; String get cardId; String get userId; String get text; DateTime? get createdAt;
/// Create a copy of PlankaComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCommentCopyWith<PlankaComment> get copyWith => _$PlankaCommentCopyWithImpl<PlankaComment>(this as PlankaComment, _$identity);

  /// Serializes this PlankaComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaComment&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,userId,text,createdAt);

@override
String toString() {
  return 'PlankaComment(id: $id, cardId: $cardId, userId: $userId, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlankaCommentCopyWith<$Res>  {
  factory $PlankaCommentCopyWith(PlankaComment value, $Res Function(PlankaComment) _then) = _$PlankaCommentCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String userId, String text, DateTime? createdAt
});




}
/// @nodoc
class _$PlankaCommentCopyWithImpl<$Res>
    implements $PlankaCommentCopyWith<$Res> {
  _$PlankaCommentCopyWithImpl(this._self, this._then);

  final PlankaComment _self;
  final $Res Function(PlankaComment) _then;

/// Create a copy of PlankaComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? userId = null,Object? text = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaComment].
extension PlankaCommentPatterns on PlankaComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaComment() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaComment value)  $default,){
final _that = this;
switch (_that) {
case _PlankaComment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaComment value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaComment() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String userId,  String text,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaComment() when $default != null:
return $default(_that.id,_that.cardId,_that.userId,_that.text,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String userId,  String text,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PlankaComment():
return $default(_that.id,_that.cardId,_that.userId,_that.text,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String userId,  String text,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PlankaComment() when $default != null:
return $default(_that.id,_that.cardId,_that.userId,_that.text,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaComment implements PlankaComment {
  const _PlankaComment({required this.id, required this.cardId, required this.userId, required this.text, this.createdAt});
  factory _PlankaComment.fromJson(Map<String, dynamic> json) => _$PlankaCommentFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String userId;
@override final  String text;
@override final  DateTime? createdAt;

/// Create a copy of PlankaComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCommentCopyWith<_PlankaComment> get copyWith => __$PlankaCommentCopyWithImpl<_PlankaComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaComment&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,userId,text,createdAt);

@override
String toString() {
  return 'PlankaComment(id: $id, cardId: $cardId, userId: $userId, text: $text, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlankaCommentCopyWith<$Res> implements $PlankaCommentCopyWith<$Res> {
  factory _$PlankaCommentCopyWith(_PlankaComment value, $Res Function(_PlankaComment) _then) = __$PlankaCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String userId, String text, DateTime? createdAt
});




}
/// @nodoc
class __$PlankaCommentCopyWithImpl<$Res>
    implements _$PlankaCommentCopyWith<$Res> {
  __$PlankaCommentCopyWithImpl(this._self, this._then);

  final _PlankaComment _self;
  final $Res Function(_PlankaComment) _then;

/// Create a copy of PlankaComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? userId = null,Object? text = null,Object? createdAt = freezed,}) {
  return _then(_PlankaComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PlankaAttachment {

 String get id; String get cardId; String get type; String get name; Map<String, dynamic>? get data; DateTime? get createdAt;
/// Create a copy of PlankaAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaAttachmentCopyWith<PlankaAttachment> get copyWith => _$PlankaAttachmentCopyWithImpl<PlankaAttachment>(this as PlankaAttachment, _$identity);

  /// Serializes this PlankaAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,type,name,const DeepCollectionEquality().hash(data),createdAt);

@override
String toString() {
  return 'PlankaAttachment(id: $id, cardId: $cardId, type: $type, name: $name, data: $data, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlankaAttachmentCopyWith<$Res>  {
  factory $PlankaAttachmentCopyWith(PlankaAttachment value, $Res Function(PlankaAttachment) _then) = _$PlankaAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String type, String name, Map<String, dynamic>? data, DateTime? createdAt
});




}
/// @nodoc
class _$PlankaAttachmentCopyWithImpl<$Res>
    implements $PlankaAttachmentCopyWith<$Res> {
  _$PlankaAttachmentCopyWithImpl(this._self, this._then);

  final PlankaAttachment _self;
  final $Res Function(PlankaAttachment) _then;

/// Create a copy of PlankaAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? type = null,Object? name = null,Object? data = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaAttachment].
extension PlankaAttachmentPatterns on PlankaAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaAttachment() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaAttachment value)  $default,){
final _that = this;
switch (_that) {
case _PlankaAttachment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaAttachment() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String type,  String name,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaAttachment() when $default != null:
return $default(_that.id,_that.cardId,_that.type,_that.name,_that.data,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String type,  String name,  Map<String, dynamic>? data,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PlankaAttachment():
return $default(_that.id,_that.cardId,_that.type,_that.name,_that.data,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String type,  String name,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PlankaAttachment() when $default != null:
return $default(_that.id,_that.cardId,_that.type,_that.name,_that.data,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaAttachment implements PlankaAttachment {
  const _PlankaAttachment({required this.id, required this.cardId, required this.type, required this.name, final  Map<String, dynamic>? data, this.createdAt}): _data = data;
  factory _PlankaAttachment.fromJson(Map<String, dynamic> json) => _$PlankaAttachmentFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String type;
@override final  String name;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;

/// Create a copy of PlankaAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaAttachmentCopyWith<_PlankaAttachment> get copyWith => __$PlankaAttachmentCopyWithImpl<_PlankaAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,type,name,const DeepCollectionEquality().hash(_data),createdAt);

@override
String toString() {
  return 'PlankaAttachment(id: $id, cardId: $cardId, type: $type, name: $name, data: $data, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlankaAttachmentCopyWith<$Res> implements $PlankaAttachmentCopyWith<$Res> {
  factory _$PlankaAttachmentCopyWith(_PlankaAttachment value, $Res Function(_PlankaAttachment) _then) = __$PlankaAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String type, String name, Map<String, dynamic>? data, DateTime? createdAt
});




}
/// @nodoc
class __$PlankaAttachmentCopyWithImpl<$Res>
    implements _$PlankaAttachmentCopyWith<$Res> {
  __$PlankaAttachmentCopyWithImpl(this._self, this._then);

  final _PlankaAttachment _self;
  final $Res Function(_PlankaAttachment) _then;

/// Create a copy of PlankaAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? type = null,Object? name = null,Object? data = freezed,Object? createdAt = freezed,}) {
  return _then(_PlankaAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PlankaNotification {

 String get id; String get userId; String get type; bool get isRead; String? get cardId; Map<String, dynamic>? get data; DateTime? get createdAt;
/// Create a copy of PlankaNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaNotificationCopyWith<PlankaNotification> get copyWith => _$PlankaNotificationCopyWithImpl<PlankaNotification>(this as PlankaNotification, _$identity);

  /// Serializes this PlankaNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,type,isRead,cardId,const DeepCollectionEquality().hash(data),createdAt);

@override
String toString() {
  return 'PlankaNotification(id: $id, userId: $userId, type: $type, isRead: $isRead, cardId: $cardId, data: $data, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlankaNotificationCopyWith<$Res>  {
  factory $PlankaNotificationCopyWith(PlankaNotification value, $Res Function(PlankaNotification) _then) = _$PlankaNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String type, bool isRead, String? cardId, Map<String, dynamic>? data, DateTime? createdAt
});




}
/// @nodoc
class _$PlankaNotificationCopyWithImpl<$Res>
    implements $PlankaNotificationCopyWith<$Res> {
  _$PlankaNotificationCopyWithImpl(this._self, this._then);

  final PlankaNotification _self;
  final $Res Function(PlankaNotification) _then;

/// Create a copy of PlankaNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? isRead = null,Object? cardId = freezed,Object? data = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaNotification].
extension PlankaNotificationPatterns on PlankaNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaNotification() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaNotification value)  $default,){
final _that = this;
switch (_that) {
case _PlankaNotification():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaNotification value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaNotification() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String type,  bool isRead,  String? cardId,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaNotification() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.isRead,_that.cardId,_that.data,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String type,  bool isRead,  String? cardId,  Map<String, dynamic>? data,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PlankaNotification():
return $default(_that.id,_that.userId,_that.type,_that.isRead,_that.cardId,_that.data,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String type,  bool isRead,  String? cardId,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PlankaNotification() when $default != null:
return $default(_that.id,_that.userId,_that.type,_that.isRead,_that.cardId,_that.data,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaNotification implements PlankaNotification {
  const _PlankaNotification({required this.id, required this.userId, required this.type, required this.isRead, this.cardId, final  Map<String, dynamic>? data, this.createdAt}): _data = data;
  factory _PlankaNotification.fromJson(Map<String, dynamic> json) => _$PlankaNotificationFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String type;
@override final  bool isRead;
@override final  String? cardId;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;

/// Create a copy of PlankaNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaNotificationCopyWith<_PlankaNotification> get copyWith => __$PlankaNotificationCopyWithImpl<_PlankaNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.type, type) || other.type == type)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,type,isRead,cardId,const DeepCollectionEquality().hash(_data),createdAt);

@override
String toString() {
  return 'PlankaNotification(id: $id, userId: $userId, type: $type, isRead: $isRead, cardId: $cardId, data: $data, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlankaNotificationCopyWith<$Res> implements $PlankaNotificationCopyWith<$Res> {
  factory _$PlankaNotificationCopyWith(_PlankaNotification value, $Res Function(_PlankaNotification) _then) = __$PlankaNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String type, bool isRead, String? cardId, Map<String, dynamic>? data, DateTime? createdAt
});




}
/// @nodoc
class __$PlankaNotificationCopyWithImpl<$Res>
    implements _$PlankaNotificationCopyWith<$Res> {
  __$PlankaNotificationCopyWithImpl(this._self, this._then);

  final _PlankaNotification _self;
  final $Res Function(_PlankaNotification) _then;

/// Create a copy of PlankaNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? type = null,Object? isRead = null,Object? cardId = freezed,Object? data = freezed,Object? createdAt = freezed,}) {
  return _then(_PlankaNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
