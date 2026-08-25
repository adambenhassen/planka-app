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

 String get id; String get name; String? get username; String? get email; Map<String, dynamic>? get avatar; String? get role; String? get phone; String? get organization; bool? get isDeactivated;
/// Create a copy of PlankaUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaUserCopyWith<PlankaUser> get copyWith => _$PlankaUserCopyWithImpl<PlankaUser>(this as PlankaUser, _$identity);

  /// Serializes this PlankaUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.avatar, avatar)&&(identical(other.role, role) || other.role == role)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.isDeactivated, isDeactivated) || other.isDeactivated == isDeactivated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,const DeepCollectionEquality().hash(avatar),role,phone,organization,isDeactivated);

@override
String toString() {
  return 'PlankaUser(id: $id, name: $name, username: $username, email: $email, avatar: $avatar, role: $role, phone: $phone, organization: $organization, isDeactivated: $isDeactivated)';
}


}

/// @nodoc
abstract mixin class $PlankaUserCopyWith<$Res>  {
  factory $PlankaUserCopyWith(PlankaUser value, $Res Function(PlankaUser) _then) = _$PlankaUserCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? username, String? email, Map<String, dynamic>? avatar, String? role, String? phone, String? organization, bool? isDeactivated
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? username = freezed,Object? email = freezed,Object? avatar = freezed,Object? role = freezed,Object? phone = freezed,Object? organization = freezed,Object? isDeactivated = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,isDeactivated: freezed == isDeactivated ? _self.isDeactivated : isDeactivated // ignore: cast_nullable_to_non_nullable
as bool?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? username,  String? email,  Map<String, dynamic>? avatar,  String? role,  String? phone,  String? organization,  bool? isDeactivated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaUser() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar,_that.role,_that.phone,_that.organization,_that.isDeactivated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? username,  String? email,  Map<String, dynamic>? avatar,  String? role,  String? phone,  String? organization,  bool? isDeactivated)  $default,) {final _that = this;
switch (_that) {
case _PlankaUser():
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar,_that.role,_that.phone,_that.organization,_that.isDeactivated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? username,  String? email,  Map<String, dynamic>? avatar,  String? role,  String? phone,  String? organization,  bool? isDeactivated)?  $default,) {final _that = this;
switch (_that) {
case _PlankaUser() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar,_that.role,_that.phone,_that.organization,_that.isDeactivated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaUser implements PlankaUser {
  const _PlankaUser({required this.id, required this.name, this.username, this.email, final  Map<String, dynamic>? avatar, this.role, this.phone, this.organization, this.isDeactivated}): _avatar = avatar;
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

@override final  String? role;
@override final  String? phone;
@override final  String? organization;
@override final  bool? isDeactivated;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._avatar, _avatar)&&(identical(other.role, role) || other.role == role)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.isDeactivated, isDeactivated) || other.isDeactivated == isDeactivated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,const DeepCollectionEquality().hash(_avatar),role,phone,organization,isDeactivated);

@override
String toString() {
  return 'PlankaUser(id: $id, name: $name, username: $username, email: $email, avatar: $avatar, role: $role, phone: $phone, organization: $organization, isDeactivated: $isDeactivated)';
}


}

/// @nodoc
abstract mixin class _$PlankaUserCopyWith<$Res> implements $PlankaUserCopyWith<$Res> {
  factory _$PlankaUserCopyWith(_PlankaUser value, $Res Function(_PlankaUser) _then) = __$PlankaUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? username, String? email, Map<String, dynamic>? avatar, String? role, String? phone, String? organization, bool? isDeactivated
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? username = freezed,Object? email = freezed,Object? avatar = freezed,Object? role = freezed,Object? phone = freezed,Object? organization = freezed,Object? isDeactivated = freezed,}) {
  return _then(_PlankaUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self._avatar : avatar // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,isDeactivated: freezed == isDeactivated ? _self.isDeactivated : isDeactivated // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$PlankaProject {

 String get id; String get name; String? get description; bool? get isFavorite; String? get backgroundType; String? get backgroundGradient; String? get backgroundImageId;
/// Create a copy of PlankaProject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaProjectCopyWith<PlankaProject> get copyWith => _$PlankaProjectCopyWithImpl<PlankaProject>(this as PlankaProject, _$identity);

  /// Serializes this PlankaProject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaProject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.backgroundType, backgroundType) || other.backgroundType == backgroundType)&&(identical(other.backgroundGradient, backgroundGradient) || other.backgroundGradient == backgroundGradient)&&(identical(other.backgroundImageId, backgroundImageId) || other.backgroundImageId == backgroundImageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,isFavorite,backgroundType,backgroundGradient,backgroundImageId);

@override
String toString() {
  return 'PlankaProject(id: $id, name: $name, description: $description, isFavorite: $isFavorite, backgroundType: $backgroundType, backgroundGradient: $backgroundGradient, backgroundImageId: $backgroundImageId)';
}


}

/// @nodoc
abstract mixin class $PlankaProjectCopyWith<$Res>  {
  factory $PlankaProjectCopyWith(PlankaProject value, $Res Function(PlankaProject) _then) = _$PlankaProjectCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, bool? isFavorite, String? backgroundType, String? backgroundGradient, String? backgroundImageId
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isFavorite = freezed,Object? backgroundType = freezed,Object? backgroundGradient = freezed,Object? backgroundImageId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,backgroundType: freezed == backgroundType ? _self.backgroundType : backgroundType // ignore: cast_nullable_to_non_nullable
as String?,backgroundGradient: freezed == backgroundGradient ? _self.backgroundGradient : backgroundGradient // ignore: cast_nullable_to_non_nullable
as String?,backgroundImageId: freezed == backgroundImageId ? _self.backgroundImageId : backgroundImageId // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  bool? isFavorite,  String? backgroundType,  String? backgroundGradient,  String? backgroundImageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaProject() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isFavorite,_that.backgroundType,_that.backgroundGradient,_that.backgroundImageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  bool? isFavorite,  String? backgroundType,  String? backgroundGradient,  String? backgroundImageId)  $default,) {final _that = this;
switch (_that) {
case _PlankaProject():
return $default(_that.id,_that.name,_that.description,_that.isFavorite,_that.backgroundType,_that.backgroundGradient,_that.backgroundImageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  bool? isFavorite,  String? backgroundType,  String? backgroundGradient,  String? backgroundImageId)?  $default,) {final _that = this;
switch (_that) {
case _PlankaProject() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isFavorite,_that.backgroundType,_that.backgroundGradient,_that.backgroundImageId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaProject implements PlankaProject {
  const _PlankaProject({required this.id, required this.name, this.description, this.isFavorite, this.backgroundType, this.backgroundGradient, this.backgroundImageId});
  factory _PlankaProject.fromJson(Map<String, dynamic> json) => _$PlankaProjectFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  bool? isFavorite;
@override final  String? backgroundType;
@override final  String? backgroundGradient;
@override final  String? backgroundImageId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaProject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.backgroundType, backgroundType) || other.backgroundType == backgroundType)&&(identical(other.backgroundGradient, backgroundGradient) || other.backgroundGradient == backgroundGradient)&&(identical(other.backgroundImageId, backgroundImageId) || other.backgroundImageId == backgroundImageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,isFavorite,backgroundType,backgroundGradient,backgroundImageId);

@override
String toString() {
  return 'PlankaProject(id: $id, name: $name, description: $description, isFavorite: $isFavorite, backgroundType: $backgroundType, backgroundGradient: $backgroundGradient, backgroundImageId: $backgroundImageId)';
}


}

/// @nodoc
abstract mixin class _$PlankaProjectCopyWith<$Res> implements $PlankaProjectCopyWith<$Res> {
  factory _$PlankaProjectCopyWith(_PlankaProject value, $Res Function(_PlankaProject) _then) = __$PlankaProjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, bool? isFavorite, String? backgroundType, String? backgroundGradient, String? backgroundImageId
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isFavorite = freezed,Object? backgroundType = freezed,Object? backgroundGradient = freezed,Object? backgroundImageId = freezed,}) {
  return _then(_PlankaProject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,backgroundType: freezed == backgroundType ? _self.backgroundType : backgroundType // ignore: cast_nullable_to_non_nullable
as String?,backgroundGradient: freezed == backgroundGradient ? _self.backgroundGradient : backgroundGradient // ignore: cast_nullable_to_non_nullable
as String?,backgroundImageId: freezed == backgroundImageId ? _self.backgroundImageId : backgroundImageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlankaBackgroundImage {

 String get id; String? get url; Map<String, dynamic>? get thumbnailUrls;
/// Create a copy of PlankaBackgroundImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaBackgroundImageCopyWith<PlankaBackgroundImage> get copyWith => _$PlankaBackgroundImageCopyWithImpl<PlankaBackgroundImage>(this as PlankaBackgroundImage, _$identity);

  /// Serializes this PlankaBackgroundImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaBackgroundImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.thumbnailUrls, thumbnailUrls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,const DeepCollectionEquality().hash(thumbnailUrls));

@override
String toString() {
  return 'PlankaBackgroundImage(id: $id, url: $url, thumbnailUrls: $thumbnailUrls)';
}


}

/// @nodoc
abstract mixin class $PlankaBackgroundImageCopyWith<$Res>  {
  factory $PlankaBackgroundImageCopyWith(PlankaBackgroundImage value, $Res Function(PlankaBackgroundImage) _then) = _$PlankaBackgroundImageCopyWithImpl;
@useResult
$Res call({
 String id, String? url, Map<String, dynamic>? thumbnailUrls
});




}
/// @nodoc
class _$PlankaBackgroundImageCopyWithImpl<$Res>
    implements $PlankaBackgroundImageCopyWith<$Res> {
  _$PlankaBackgroundImageCopyWithImpl(this._self, this._then);

  final PlankaBackgroundImage _self;
  final $Res Function(PlankaBackgroundImage) _then;

/// Create a copy of PlankaBackgroundImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = freezed,Object? thumbnailUrls = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrls: freezed == thumbnailUrls ? _self.thumbnailUrls : thumbnailUrls // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaBackgroundImage].
extension PlankaBackgroundImagePatterns on PlankaBackgroundImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaBackgroundImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaBackgroundImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaBackgroundImage value)  $default,){
final _that = this;
switch (_that) {
case _PlankaBackgroundImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaBackgroundImage value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaBackgroundImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? url,  Map<String, dynamic>? thumbnailUrls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaBackgroundImage() when $default != null:
return $default(_that.id,_that.url,_that.thumbnailUrls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? url,  Map<String, dynamic>? thumbnailUrls)  $default,) {final _that = this;
switch (_that) {
case _PlankaBackgroundImage():
return $default(_that.id,_that.url,_that.thumbnailUrls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? url,  Map<String, dynamic>? thumbnailUrls)?  $default,) {final _that = this;
switch (_that) {
case _PlankaBackgroundImage() when $default != null:
return $default(_that.id,_that.url,_that.thumbnailUrls);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaBackgroundImage implements PlankaBackgroundImage {
  const _PlankaBackgroundImage({required this.id, this.url, final  Map<String, dynamic>? thumbnailUrls}): _thumbnailUrls = thumbnailUrls;
  factory _PlankaBackgroundImage.fromJson(Map<String, dynamic> json) => _$PlankaBackgroundImageFromJson(json);

@override final  String id;
@override final  String? url;
 final  Map<String, dynamic>? _thumbnailUrls;
@override Map<String, dynamic>? get thumbnailUrls {
  final value = _thumbnailUrls;
  if (value == null) return null;
  if (_thumbnailUrls is EqualUnmodifiableMapView) return _thumbnailUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PlankaBackgroundImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaBackgroundImageCopyWith<_PlankaBackgroundImage> get copyWith => __$PlankaBackgroundImageCopyWithImpl<_PlankaBackgroundImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaBackgroundImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaBackgroundImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._thumbnailUrls, _thumbnailUrls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,const DeepCollectionEquality().hash(_thumbnailUrls));

@override
String toString() {
  return 'PlankaBackgroundImage(id: $id, url: $url, thumbnailUrls: $thumbnailUrls)';
}


}

/// @nodoc
abstract mixin class _$PlankaBackgroundImageCopyWith<$Res> implements $PlankaBackgroundImageCopyWith<$Res> {
  factory _$PlankaBackgroundImageCopyWith(_PlankaBackgroundImage value, $Res Function(_PlankaBackgroundImage) _then) = __$PlankaBackgroundImageCopyWithImpl;
@override @useResult
$Res call({
 String id, String? url, Map<String, dynamic>? thumbnailUrls
});




}
/// @nodoc
class __$PlankaBackgroundImageCopyWithImpl<$Res>
    implements _$PlankaBackgroundImageCopyWith<$Res> {
  __$PlankaBackgroundImageCopyWithImpl(this._self, this._then);

  final _PlankaBackgroundImage _self;
  final $Res Function(_PlankaBackgroundImage) _then;

/// Create a copy of PlankaBackgroundImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = freezed,Object? thumbnailUrls = freezed,}) {
  return _then(_PlankaBackgroundImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrls: freezed == thumbnailUrls ? _self._thumbnailUrls : thumbnailUrls // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$PlankaBoard {

 String get id; String get projectId; String get name;@JsonKey(fromJson: _toDouble) double? get position; String? get defaultView; String? get defaultCardType; bool? get limitCardTypesToDefaultOne; bool? get alwaysDisplayCardCreator; bool? get displayCardAges; bool? get expandTaskListsByDefault;
/// Create a copy of PlankaBoard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaBoardCopyWith<PlankaBoard> get copyWith => _$PlankaBoardCopyWithImpl<PlankaBoard>(this as PlankaBoard, _$identity);

  /// Serializes this PlankaBoard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaBoard&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.defaultView, defaultView) || other.defaultView == defaultView)&&(identical(other.defaultCardType, defaultCardType) || other.defaultCardType == defaultCardType)&&(identical(other.limitCardTypesToDefaultOne, limitCardTypesToDefaultOne) || other.limitCardTypesToDefaultOne == limitCardTypesToDefaultOne)&&(identical(other.alwaysDisplayCardCreator, alwaysDisplayCardCreator) || other.alwaysDisplayCardCreator == alwaysDisplayCardCreator)&&(identical(other.displayCardAges, displayCardAges) || other.displayCardAges == displayCardAges)&&(identical(other.expandTaskListsByDefault, expandTaskListsByDefault) || other.expandTaskListsByDefault == expandTaskListsByDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,name,position,defaultView,defaultCardType,limitCardTypesToDefaultOne,alwaysDisplayCardCreator,displayCardAges,expandTaskListsByDefault);

@override
String toString() {
  return 'PlankaBoard(id: $id, projectId: $projectId, name: $name, position: $position, defaultView: $defaultView, defaultCardType: $defaultCardType, limitCardTypesToDefaultOne: $limitCardTypesToDefaultOne, alwaysDisplayCardCreator: $alwaysDisplayCardCreator, displayCardAges: $displayCardAges, expandTaskListsByDefault: $expandTaskListsByDefault)';
}


}

/// @nodoc
abstract mixin class $PlankaBoardCopyWith<$Res>  {
  factory $PlankaBoardCopyWith(PlankaBoard value, $Res Function(PlankaBoard) _then) = _$PlankaBoardCopyWithImpl;
@useResult
$Res call({
 String id, String projectId, String name,@JsonKey(fromJson: _toDouble) double? position, String? defaultView, String? defaultCardType, bool? limitCardTypesToDefaultOne, bool? alwaysDisplayCardCreator, bool? displayCardAges, bool? expandTaskListsByDefault
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? name = null,Object? position = freezed,Object? defaultView = freezed,Object? defaultCardType = freezed,Object? limitCardTypesToDefaultOne = freezed,Object? alwaysDisplayCardCreator = freezed,Object? displayCardAges = freezed,Object? expandTaskListsByDefault = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,defaultView: freezed == defaultView ? _self.defaultView : defaultView // ignore: cast_nullable_to_non_nullable
as String?,defaultCardType: freezed == defaultCardType ? _self.defaultCardType : defaultCardType // ignore: cast_nullable_to_non_nullable
as String?,limitCardTypesToDefaultOne: freezed == limitCardTypesToDefaultOne ? _self.limitCardTypesToDefaultOne : limitCardTypesToDefaultOne // ignore: cast_nullable_to_non_nullable
as bool?,alwaysDisplayCardCreator: freezed == alwaysDisplayCardCreator ? _self.alwaysDisplayCardCreator : alwaysDisplayCardCreator // ignore: cast_nullable_to_non_nullable
as bool?,displayCardAges: freezed == displayCardAges ? _self.displayCardAges : displayCardAges // ignore: cast_nullable_to_non_nullable
as bool?,expandTaskListsByDefault: freezed == expandTaskListsByDefault ? _self.expandTaskListsByDefault : expandTaskListsByDefault // ignore: cast_nullable_to_non_nullable
as bool?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectId,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? defaultView,  String? defaultCardType,  bool? limitCardTypesToDefaultOne,  bool? alwaysDisplayCardCreator,  bool? displayCardAges,  bool? expandTaskListsByDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaBoard() when $default != null:
return $default(_that.id,_that.projectId,_that.name,_that.position,_that.defaultView,_that.defaultCardType,_that.limitCardTypesToDefaultOne,_that.alwaysDisplayCardCreator,_that.displayCardAges,_that.expandTaskListsByDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectId,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? defaultView,  String? defaultCardType,  bool? limitCardTypesToDefaultOne,  bool? alwaysDisplayCardCreator,  bool? displayCardAges,  bool? expandTaskListsByDefault)  $default,) {final _that = this;
switch (_that) {
case _PlankaBoard():
return $default(_that.id,_that.projectId,_that.name,_that.position,_that.defaultView,_that.defaultCardType,_that.limitCardTypesToDefaultOne,_that.alwaysDisplayCardCreator,_that.displayCardAges,_that.expandTaskListsByDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectId,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? defaultView,  String? defaultCardType,  bool? limitCardTypesToDefaultOne,  bool? alwaysDisplayCardCreator,  bool? displayCardAges,  bool? expandTaskListsByDefault)?  $default,) {final _that = this;
switch (_that) {
case _PlankaBoard() when $default != null:
return $default(_that.id,_that.projectId,_that.name,_that.position,_that.defaultView,_that.defaultCardType,_that.limitCardTypesToDefaultOne,_that.alwaysDisplayCardCreator,_that.displayCardAges,_that.expandTaskListsByDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaBoard implements PlankaBoard {
  const _PlankaBoard({required this.id, required this.projectId, required this.name, @JsonKey(fromJson: _toDouble) this.position, this.defaultView, this.defaultCardType, this.limitCardTypesToDefaultOne, this.alwaysDisplayCardCreator, this.displayCardAges, this.expandTaskListsByDefault});
  factory _PlankaBoard.fromJson(Map<String, dynamic> json) => _$PlankaBoardFromJson(json);

@override final  String id;
@override final  String projectId;
@override final  String name;
@override@JsonKey(fromJson: _toDouble) final  double? position;
@override final  String? defaultView;
@override final  String? defaultCardType;
@override final  bool? limitCardTypesToDefaultOne;
@override final  bool? alwaysDisplayCardCreator;
@override final  bool? displayCardAges;
@override final  bool? expandTaskListsByDefault;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaBoard&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.defaultView, defaultView) || other.defaultView == defaultView)&&(identical(other.defaultCardType, defaultCardType) || other.defaultCardType == defaultCardType)&&(identical(other.limitCardTypesToDefaultOne, limitCardTypesToDefaultOne) || other.limitCardTypesToDefaultOne == limitCardTypesToDefaultOne)&&(identical(other.alwaysDisplayCardCreator, alwaysDisplayCardCreator) || other.alwaysDisplayCardCreator == alwaysDisplayCardCreator)&&(identical(other.displayCardAges, displayCardAges) || other.displayCardAges == displayCardAges)&&(identical(other.expandTaskListsByDefault, expandTaskListsByDefault) || other.expandTaskListsByDefault == expandTaskListsByDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,name,position,defaultView,defaultCardType,limitCardTypesToDefaultOne,alwaysDisplayCardCreator,displayCardAges,expandTaskListsByDefault);

@override
String toString() {
  return 'PlankaBoard(id: $id, projectId: $projectId, name: $name, position: $position, defaultView: $defaultView, defaultCardType: $defaultCardType, limitCardTypesToDefaultOne: $limitCardTypesToDefaultOne, alwaysDisplayCardCreator: $alwaysDisplayCardCreator, displayCardAges: $displayCardAges, expandTaskListsByDefault: $expandTaskListsByDefault)';
}


}

/// @nodoc
abstract mixin class _$PlankaBoardCopyWith<$Res> implements $PlankaBoardCopyWith<$Res> {
  factory _$PlankaBoardCopyWith(_PlankaBoard value, $Res Function(_PlankaBoard) _then) = __$PlankaBoardCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectId, String name,@JsonKey(fromJson: _toDouble) double? position, String? defaultView, String? defaultCardType, bool? limitCardTypesToDefaultOne, bool? alwaysDisplayCardCreator, bool? displayCardAges, bool? expandTaskListsByDefault
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? name = null,Object? position = freezed,Object? defaultView = freezed,Object? defaultCardType = freezed,Object? limitCardTypesToDefaultOne = freezed,Object? alwaysDisplayCardCreator = freezed,Object? displayCardAges = freezed,Object? expandTaskListsByDefault = freezed,}) {
  return _then(_PlankaBoard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,defaultView: freezed == defaultView ? _self.defaultView : defaultView // ignore: cast_nullable_to_non_nullable
as String?,defaultCardType: freezed == defaultCardType ? _self.defaultCardType : defaultCardType // ignore: cast_nullable_to_non_nullable
as String?,limitCardTypesToDefaultOne: freezed == limitCardTypesToDefaultOne ? _self.limitCardTypesToDefaultOne : limitCardTypesToDefaultOne // ignore: cast_nullable_to_non_nullable
as bool?,alwaysDisplayCardCreator: freezed == alwaysDisplayCardCreator ? _self.alwaysDisplayCardCreator : alwaysDisplayCardCreator // ignore: cast_nullable_to_non_nullable
as bool?,displayCardAges: freezed == displayCardAges ? _self.displayCardAges : displayCardAges // ignore: cast_nullable_to_non_nullable
as bool?,expandTaskListsByDefault: freezed == expandTaskListsByDefault ? _self.expandTaskListsByDefault : expandTaskListsByDefault // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$PlankaList {

 String get id; String get boardId;@JsonKey(unknownEnumValue: PlankaListType.unknown) PlankaListType get type; String? get name;@JsonKey(fromJson: _toDouble) double? get position; String? get color;
/// Create a copy of PlankaList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaListCopyWith<PlankaList> get copyWith => _$PlankaListCopyWithImpl<PlankaList>(this as PlankaList, _$identity);

  /// Serializes this PlankaList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaList&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,type,name,position,color);

@override
String toString() {
  return 'PlankaList(id: $id, boardId: $boardId, type: $type, name: $name, position: $position, color: $color)';
}


}

/// @nodoc
abstract mixin class $PlankaListCopyWith<$Res>  {
  factory $PlankaListCopyWith(PlankaList value, $Res Function(PlankaList) _then) = _$PlankaListCopyWithImpl;
@useResult
$Res call({
 String id, String boardId,@JsonKey(unknownEnumValue: PlankaListType.unknown) PlankaListType type, String? name,@JsonKey(fromJson: _toDouble) double? position, String? color
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? type = null,Object? name = freezed,Object? position = freezed,Object? color = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlankaListType,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId, @JsonKey(unknownEnumValue: PlankaListType.unknown)  PlankaListType type,  String? name, @JsonKey(fromJson: _toDouble)  double? position,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaList() when $default != null:
return $default(_that.id,_that.boardId,_that.type,_that.name,_that.position,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId, @JsonKey(unknownEnumValue: PlankaListType.unknown)  PlankaListType type,  String? name, @JsonKey(fromJson: _toDouble)  double? position,  String? color)  $default,) {final _that = this;
switch (_that) {
case _PlankaList():
return $default(_that.id,_that.boardId,_that.type,_that.name,_that.position,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId, @JsonKey(unknownEnumValue: PlankaListType.unknown)  PlankaListType type,  String? name, @JsonKey(fromJson: _toDouble)  double? position,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _PlankaList() when $default != null:
return $default(_that.id,_that.boardId,_that.type,_that.name,_that.position,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaList implements PlankaList {
  const _PlankaList({required this.id, required this.boardId, @JsonKey(unknownEnumValue: PlankaListType.unknown) required this.type, this.name, @JsonKey(fromJson: _toDouble) this.position, this.color});
  factory _PlankaList.fromJson(Map<String, dynamic> json) => _$PlankaListFromJson(json);

@override final  String id;
@override final  String boardId;
@override@JsonKey(unknownEnumValue: PlankaListType.unknown) final  PlankaListType type;
@override final  String? name;
@override@JsonKey(fromJson: _toDouble) final  double? position;
@override final  String? color;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaList&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,type,name,position,color);

@override
String toString() {
  return 'PlankaList(id: $id, boardId: $boardId, type: $type, name: $name, position: $position, color: $color)';
}


}

/// @nodoc
abstract mixin class _$PlankaListCopyWith<$Res> implements $PlankaListCopyWith<$Res> {
  factory _$PlankaListCopyWith(_PlankaList value, $Res Function(_PlankaList) _then) = __$PlankaListCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId,@JsonKey(unknownEnumValue: PlankaListType.unknown) PlankaListType type, String? name,@JsonKey(fromJson: _toDouble) double? position, String? color
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? type = null,Object? name = freezed,Object? position = freezed,Object? color = freezed,}) {
  return _then(_PlankaList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,boardId: null == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlankaListType,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlankaCard {

 String get id; String get boardId; String get listId; String get type; String get name;@JsonKey(fromJson: _toDouble) double? get position; String? get description; DateTime? get dueDate; bool? get isDueCompleted; String? get coverAttachmentId; bool? get isSubscribed; PlankaStopwatch? get stopwatch; DateTime? get createdAt; String? get prevListId; String? get creatorUserId; DateTime? get listChangedAt;@JsonKey(fromJson: _toIntOrNull) int? get commentsTotal;/// Server-derived: true while the card sits in a `closed`-type list.
 bool? get isClosed;
/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCardCopyWith<PlankaCard> get copyWith => _$PlankaCardCopyWithImpl<PlankaCard>(this as PlankaCard, _$identity);

  /// Serializes this PlankaCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCard&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isDueCompleted, isDueCompleted) || other.isDueCompleted == isDueCompleted)&&(identical(other.coverAttachmentId, coverAttachmentId) || other.coverAttachmentId == coverAttachmentId)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.stopwatch, stopwatch) || other.stopwatch == stopwatch)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.prevListId, prevListId) || other.prevListId == prevListId)&&(identical(other.creatorUserId, creatorUserId) || other.creatorUserId == creatorUserId)&&(identical(other.listChangedAt, listChangedAt) || other.listChangedAt == listChangedAt)&&(identical(other.commentsTotal, commentsTotal) || other.commentsTotal == commentsTotal)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,listId,type,name,position,description,dueDate,isDueCompleted,coverAttachmentId,isSubscribed,stopwatch,createdAt,prevListId,creatorUserId,listChangedAt,commentsTotal,isClosed);

@override
String toString() {
  return 'PlankaCard(id: $id, boardId: $boardId, listId: $listId, type: $type, name: $name, position: $position, description: $description, dueDate: $dueDate, isDueCompleted: $isDueCompleted, coverAttachmentId: $coverAttachmentId, isSubscribed: $isSubscribed, stopwatch: $stopwatch, createdAt: $createdAt, prevListId: $prevListId, creatorUserId: $creatorUserId, listChangedAt: $listChangedAt, commentsTotal: $commentsTotal, isClosed: $isClosed)';
}


}

/// @nodoc
abstract mixin class $PlankaCardCopyWith<$Res>  {
  factory $PlankaCardCopyWith(PlankaCard value, $Res Function(PlankaCard) _then) = _$PlankaCardCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String listId, String type, String name,@JsonKey(fromJson: _toDouble) double? position, String? description, DateTime? dueDate, bool? isDueCompleted, String? coverAttachmentId, bool? isSubscribed, PlankaStopwatch? stopwatch, DateTime? createdAt, String? prevListId, String? creatorUserId, DateTime? listChangedAt,@JsonKey(fromJson: _toIntOrNull) int? commentsTotal, bool? isClosed
});


$PlankaStopwatchCopyWith<$Res>? get stopwatch;

}
/// @nodoc
class _$PlankaCardCopyWithImpl<$Res>
    implements $PlankaCardCopyWith<$Res> {
  _$PlankaCardCopyWithImpl(this._self, this._then);

  final PlankaCard _self;
  final $Res Function(PlankaCard) _then;

/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? boardId = null,Object? listId = null,Object? type = null,Object? name = null,Object? position = freezed,Object? description = freezed,Object? dueDate = freezed,Object? isDueCompleted = freezed,Object? coverAttachmentId = freezed,Object? isSubscribed = freezed,Object? stopwatch = freezed,Object? createdAt = freezed,Object? prevListId = freezed,Object? creatorUserId = freezed,Object? listChangedAt = freezed,Object? commentsTotal = freezed,Object? isClosed = freezed,}) {
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
as String?,isSubscribed: freezed == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool?,stopwatch: freezed == stopwatch ? _self.stopwatch : stopwatch // ignore: cast_nullable_to_non_nullable
as PlankaStopwatch?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,prevListId: freezed == prevListId ? _self.prevListId : prevListId // ignore: cast_nullable_to_non_nullable
as String?,creatorUserId: freezed == creatorUserId ? _self.creatorUserId : creatorUserId // ignore: cast_nullable_to_non_nullable
as String?,listChangedAt: freezed == listChangedAt ? _self.listChangedAt : listChangedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,commentsTotal: freezed == commentsTotal ? _self.commentsTotal : commentsTotal // ignore: cast_nullable_to_non_nullable
as int?,isClosed: freezed == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlankaStopwatchCopyWith<$Res>? get stopwatch {
    if (_self.stopwatch == null) {
    return null;
  }

  return $PlankaStopwatchCopyWith<$Res>(_self.stopwatch!, (value) {
    return _then(_self.copyWith(stopwatch: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String boardId,  String listId,  String type,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? description,  DateTime? dueDate,  bool? isDueCompleted,  String? coverAttachmentId,  bool? isSubscribed,  PlankaStopwatch? stopwatch,  DateTime? createdAt,  String? prevListId,  String? creatorUserId,  DateTime? listChangedAt, @JsonKey(fromJson: _toIntOrNull)  int? commentsTotal,  bool? isClosed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaCard() when $default != null:
return $default(_that.id,_that.boardId,_that.listId,_that.type,_that.name,_that.position,_that.description,_that.dueDate,_that.isDueCompleted,_that.coverAttachmentId,_that.isSubscribed,_that.stopwatch,_that.createdAt,_that.prevListId,_that.creatorUserId,_that.listChangedAt,_that.commentsTotal,_that.isClosed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String boardId,  String listId,  String type,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? description,  DateTime? dueDate,  bool? isDueCompleted,  String? coverAttachmentId,  bool? isSubscribed,  PlankaStopwatch? stopwatch,  DateTime? createdAt,  String? prevListId,  String? creatorUserId,  DateTime? listChangedAt, @JsonKey(fromJson: _toIntOrNull)  int? commentsTotal,  bool? isClosed)  $default,) {final _that = this;
switch (_that) {
case _PlankaCard():
return $default(_that.id,_that.boardId,_that.listId,_that.type,_that.name,_that.position,_that.description,_that.dueDate,_that.isDueCompleted,_that.coverAttachmentId,_that.isSubscribed,_that.stopwatch,_that.createdAt,_that.prevListId,_that.creatorUserId,_that.listChangedAt,_that.commentsTotal,_that.isClosed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String boardId,  String listId,  String type,  String name, @JsonKey(fromJson: _toDouble)  double? position,  String? description,  DateTime? dueDate,  bool? isDueCompleted,  String? coverAttachmentId,  bool? isSubscribed,  PlankaStopwatch? stopwatch,  DateTime? createdAt,  String? prevListId,  String? creatorUserId,  DateTime? listChangedAt, @JsonKey(fromJson: _toIntOrNull)  int? commentsTotal,  bool? isClosed)?  $default,) {final _that = this;
switch (_that) {
case _PlankaCard() when $default != null:
return $default(_that.id,_that.boardId,_that.listId,_that.type,_that.name,_that.position,_that.description,_that.dueDate,_that.isDueCompleted,_that.coverAttachmentId,_that.isSubscribed,_that.stopwatch,_that.createdAt,_that.prevListId,_that.creatorUserId,_that.listChangedAt,_that.commentsTotal,_that.isClosed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCard implements PlankaCard {
  const _PlankaCard({required this.id, required this.boardId, required this.listId, required this.type, required this.name, @JsonKey(fromJson: _toDouble) this.position, this.description, this.dueDate, this.isDueCompleted, this.coverAttachmentId, this.isSubscribed, this.stopwatch, this.createdAt, this.prevListId, this.creatorUserId, this.listChangedAt, @JsonKey(fromJson: _toIntOrNull) this.commentsTotal, this.isClosed});
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
@override final  bool? isSubscribed;
@override final  PlankaStopwatch? stopwatch;
@override final  DateTime? createdAt;
@override final  String? prevListId;
@override final  String? creatorUserId;
@override final  DateTime? listChangedAt;
@override@JsonKey(fromJson: _toIntOrNull) final  int? commentsTotal;
/// Server-derived: true while the card sits in a `closed`-type list.
@override final  bool? isClosed;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCard&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isDueCompleted, isDueCompleted) || other.isDueCompleted == isDueCompleted)&&(identical(other.coverAttachmentId, coverAttachmentId) || other.coverAttachmentId == coverAttachmentId)&&(identical(other.isSubscribed, isSubscribed) || other.isSubscribed == isSubscribed)&&(identical(other.stopwatch, stopwatch) || other.stopwatch == stopwatch)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.prevListId, prevListId) || other.prevListId == prevListId)&&(identical(other.creatorUserId, creatorUserId) || other.creatorUserId == creatorUserId)&&(identical(other.listChangedAt, listChangedAt) || other.listChangedAt == listChangedAt)&&(identical(other.commentsTotal, commentsTotal) || other.commentsTotal == commentsTotal)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,listId,type,name,position,description,dueDate,isDueCompleted,coverAttachmentId,isSubscribed,stopwatch,createdAt,prevListId,creatorUserId,listChangedAt,commentsTotal,isClosed);

@override
String toString() {
  return 'PlankaCard(id: $id, boardId: $boardId, listId: $listId, type: $type, name: $name, position: $position, description: $description, dueDate: $dueDate, isDueCompleted: $isDueCompleted, coverAttachmentId: $coverAttachmentId, isSubscribed: $isSubscribed, stopwatch: $stopwatch, createdAt: $createdAt, prevListId: $prevListId, creatorUserId: $creatorUserId, listChangedAt: $listChangedAt, commentsTotal: $commentsTotal, isClosed: $isClosed)';
}


}

/// @nodoc
abstract mixin class _$PlankaCardCopyWith<$Res> implements $PlankaCardCopyWith<$Res> {
  factory _$PlankaCardCopyWith(_PlankaCard value, $Res Function(_PlankaCard) _then) = __$PlankaCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String listId, String type, String name,@JsonKey(fromJson: _toDouble) double? position, String? description, DateTime? dueDate, bool? isDueCompleted, String? coverAttachmentId, bool? isSubscribed, PlankaStopwatch? stopwatch, DateTime? createdAt, String? prevListId, String? creatorUserId, DateTime? listChangedAt,@JsonKey(fromJson: _toIntOrNull) int? commentsTotal, bool? isClosed
});


@override $PlankaStopwatchCopyWith<$Res>? get stopwatch;

}
/// @nodoc
class __$PlankaCardCopyWithImpl<$Res>
    implements _$PlankaCardCopyWith<$Res> {
  __$PlankaCardCopyWithImpl(this._self, this._then);

  final _PlankaCard _self;
  final $Res Function(_PlankaCard) _then;

/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? listId = null,Object? type = null,Object? name = null,Object? position = freezed,Object? description = freezed,Object? dueDate = freezed,Object? isDueCompleted = freezed,Object? coverAttachmentId = freezed,Object? isSubscribed = freezed,Object? stopwatch = freezed,Object? createdAt = freezed,Object? prevListId = freezed,Object? creatorUserId = freezed,Object? listChangedAt = freezed,Object? commentsTotal = freezed,Object? isClosed = freezed,}) {
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
as String?,isSubscribed: freezed == isSubscribed ? _self.isSubscribed : isSubscribed // ignore: cast_nullable_to_non_nullable
as bool?,stopwatch: freezed == stopwatch ? _self.stopwatch : stopwatch // ignore: cast_nullable_to_non_nullable
as PlankaStopwatch?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,prevListId: freezed == prevListId ? _self.prevListId : prevListId // ignore: cast_nullable_to_non_nullable
as String?,creatorUserId: freezed == creatorUserId ? _self.creatorUserId : creatorUserId // ignore: cast_nullable_to_non_nullable
as String?,listChangedAt: freezed == listChangedAt ? _self.listChangedAt : listChangedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,commentsTotal: freezed == commentsTotal ? _self.commentsTotal : commentsTotal // ignore: cast_nullable_to_non_nullable
as int?,isClosed: freezed == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of PlankaCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlankaStopwatchCopyWith<$Res>? get stopwatch {
    if (_self.stopwatch == null) {
    return null;
  }

  return $PlankaStopwatchCopyWith<$Res>(_self.stopwatch!, (value) {
    return _then(_self.copyWith(stopwatch: value));
  });
}
}


/// @nodoc
mixin _$PlankaStopwatch {

 DateTime? get startedAt;@JsonKey(fromJson: _toInt) int get total;
/// Create a copy of PlankaStopwatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaStopwatchCopyWith<PlankaStopwatch> get copyWith => _$PlankaStopwatchCopyWithImpl<PlankaStopwatch>(this as PlankaStopwatch, _$identity);

  /// Serializes this PlankaStopwatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaStopwatch&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startedAt,total);

@override
String toString() {
  return 'PlankaStopwatch(startedAt: $startedAt, total: $total)';
}


}

/// @nodoc
abstract mixin class $PlankaStopwatchCopyWith<$Res>  {
  factory $PlankaStopwatchCopyWith(PlankaStopwatch value, $Res Function(PlankaStopwatch) _then) = _$PlankaStopwatchCopyWithImpl;
@useResult
$Res call({
 DateTime? startedAt,@JsonKey(fromJson: _toInt) int total
});




}
/// @nodoc
class _$PlankaStopwatchCopyWithImpl<$Res>
    implements $PlankaStopwatchCopyWith<$Res> {
  _$PlankaStopwatchCopyWithImpl(this._self, this._then);

  final PlankaStopwatch _self;
  final $Res Function(PlankaStopwatch) _then;

/// Create a copy of PlankaStopwatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startedAt = freezed,Object? total = null,}) {
  return _then(_self.copyWith(
startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaStopwatch].
extension PlankaStopwatchPatterns on PlankaStopwatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaStopwatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaStopwatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaStopwatch value)  $default,){
final _that = this;
switch (_that) {
case _PlankaStopwatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaStopwatch value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaStopwatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? startedAt, @JsonKey(fromJson: _toInt)  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaStopwatch() when $default != null:
return $default(_that.startedAt,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? startedAt, @JsonKey(fromJson: _toInt)  int total)  $default,) {final _that = this;
switch (_that) {
case _PlankaStopwatch():
return $default(_that.startedAt,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? startedAt, @JsonKey(fromJson: _toInt)  int total)?  $default,) {final _that = this;
switch (_that) {
case _PlankaStopwatch() when $default != null:
return $default(_that.startedAt,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaStopwatch implements PlankaStopwatch {
  const _PlankaStopwatch({this.startedAt, @JsonKey(fromJson: _toInt) required this.total});
  factory _PlankaStopwatch.fromJson(Map<String, dynamic> json) => _$PlankaStopwatchFromJson(json);

@override final  DateTime? startedAt;
@override@JsonKey(fromJson: _toInt) final  int total;

/// Create a copy of PlankaStopwatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaStopwatchCopyWith<_PlankaStopwatch> get copyWith => __$PlankaStopwatchCopyWithImpl<_PlankaStopwatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaStopwatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaStopwatch&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startedAt,total);

@override
String toString() {
  return 'PlankaStopwatch(startedAt: $startedAt, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PlankaStopwatchCopyWith<$Res> implements $PlankaStopwatchCopyWith<$Res> {
  factory _$PlankaStopwatchCopyWith(_PlankaStopwatch value, $Res Function(_PlankaStopwatch) _then) = __$PlankaStopwatchCopyWithImpl;
@override @useResult
$Res call({
 DateTime? startedAt,@JsonKey(fromJson: _toInt) int total
});




}
/// @nodoc
class __$PlankaStopwatchCopyWithImpl<$Res>
    implements _$PlankaStopwatchCopyWith<$Res> {
  __$PlankaStopwatchCopyWithImpl(this._self, this._then);

  final _PlankaStopwatch _self;
  final $Res Function(_PlankaStopwatch) _then;

/// Create a copy of PlankaStopwatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startedAt = freezed,Object? total = null,}) {
  return _then(_PlankaStopwatch(
startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
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
mixin _$PlankaCardLabel {

 String get id; String get cardId; String get labelId;
/// Create a copy of PlankaCardLabel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCardLabelCopyWith<PlankaCardLabel> get copyWith => _$PlankaCardLabelCopyWithImpl<PlankaCardLabel>(this as PlankaCardLabel, _$identity);

  /// Serializes this PlankaCardLabel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCardLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.labelId, labelId) || other.labelId == labelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,labelId);

@override
String toString() {
  return 'PlankaCardLabel(id: $id, cardId: $cardId, labelId: $labelId)';
}


}

/// @nodoc
abstract mixin class $PlankaCardLabelCopyWith<$Res>  {
  factory $PlankaCardLabelCopyWith(PlankaCardLabel value, $Res Function(PlankaCardLabel) _then) = _$PlankaCardLabelCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String labelId
});




}
/// @nodoc
class _$PlankaCardLabelCopyWithImpl<$Res>
    implements $PlankaCardLabelCopyWith<$Res> {
  _$PlankaCardLabelCopyWithImpl(this._self, this._then);

  final PlankaCardLabel _self;
  final $Res Function(PlankaCardLabel) _then;

/// Create a copy of PlankaCardLabel
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


/// Adds pattern-matching-related methods to [PlankaCardLabel].
extension PlankaCardLabelPatterns on PlankaCardLabel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaCardLabel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaCardLabel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaCardLabel value)  $default,){
final _that = this;
switch (_that) {
case _PlankaCardLabel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaCardLabel value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaCardLabel() when $default != null:
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
case _PlankaCardLabel() when $default != null:
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
case _PlankaCardLabel():
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
case _PlankaCardLabel() when $default != null:
return $default(_that.id,_that.cardId,_that.labelId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCardLabel implements PlankaCardLabel {
  const _PlankaCardLabel({required this.id, required this.cardId, required this.labelId});
  factory _PlankaCardLabel.fromJson(Map<String, dynamic> json) => _$PlankaCardLabelFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String labelId;

/// Create a copy of PlankaCardLabel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCardLabelCopyWith<_PlankaCardLabel> get copyWith => __$PlankaCardLabelCopyWithImpl<_PlankaCardLabel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCardLabelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCardLabel&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.labelId, labelId) || other.labelId == labelId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,labelId);

@override
String toString() {
  return 'PlankaCardLabel(id: $id, cardId: $cardId, labelId: $labelId)';
}


}

/// @nodoc
abstract mixin class _$PlankaCardLabelCopyWith<$Res> implements $PlankaCardLabelCopyWith<$Res> {
  factory _$PlankaCardLabelCopyWith(_PlankaCardLabel value, $Res Function(_PlankaCardLabel) _then) = __$PlankaCardLabelCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String labelId
});




}
/// @nodoc
class __$PlankaCardLabelCopyWithImpl<$Res>
    implements _$PlankaCardLabelCopyWith<$Res> {
  __$PlankaCardLabelCopyWithImpl(this._self, this._then);

  final _PlankaCardLabel _self;
  final $Res Function(_PlankaCardLabel) _then;

/// Create a copy of PlankaCardLabel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? labelId = null,}) {
  return _then(_PlankaCardLabel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,labelId: null == labelId ? _self.labelId : labelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlankaCardMembership {

 String get id; String get cardId; String get userId;
/// Create a copy of PlankaCardMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCardMembershipCopyWith<PlankaCardMembership> get copyWith => _$PlankaCardMembershipCopyWithImpl<PlankaCardMembership>(this as PlankaCardMembership, _$identity);

  /// Serializes this PlankaCardMembership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,userId);

@override
String toString() {
  return 'PlankaCardMembership(id: $id, cardId: $cardId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class $PlankaCardMembershipCopyWith<$Res>  {
  factory $PlankaCardMembershipCopyWith(PlankaCardMembership value, $Res Function(PlankaCardMembership) _then) = _$PlankaCardMembershipCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String userId
});




}
/// @nodoc
class _$PlankaCardMembershipCopyWithImpl<$Res>
    implements $PlankaCardMembershipCopyWith<$Res> {
  _$PlankaCardMembershipCopyWithImpl(this._self, this._then);

  final PlankaCardMembership _self;
  final $Res Function(PlankaCardMembership) _then;

/// Create a copy of PlankaCardMembership
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


/// Adds pattern-matching-related methods to [PlankaCardMembership].
extension PlankaCardMembershipPatterns on PlankaCardMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaCardMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaCardMembership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaCardMembership value)  $default,){
final _that = this;
switch (_that) {
case _PlankaCardMembership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaCardMembership value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaCardMembership() when $default != null:
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
case _PlankaCardMembership() when $default != null:
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
case _PlankaCardMembership():
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
case _PlankaCardMembership() when $default != null:
return $default(_that.id,_that.cardId,_that.userId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCardMembership implements PlankaCardMembership {
  const _PlankaCardMembership({required this.id, required this.cardId, required this.userId});
  factory _PlankaCardMembership.fromJson(Map<String, dynamic> json) => _$PlankaCardMembershipFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String userId;

/// Create a copy of PlankaCardMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCardMembershipCopyWith<_PlankaCardMembership> get copyWith => __$PlankaCardMembershipCopyWithImpl<_PlankaCardMembership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCardMembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,userId);

@override
String toString() {
  return 'PlankaCardMembership(id: $id, cardId: $cardId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class _$PlankaCardMembershipCopyWith<$Res> implements $PlankaCardMembershipCopyWith<$Res> {
  factory _$PlankaCardMembershipCopyWith(_PlankaCardMembership value, $Res Function(_PlankaCardMembership) _then) = __$PlankaCardMembershipCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String userId
});




}
/// @nodoc
class __$PlankaCardMembershipCopyWithImpl<$Res>
    implements _$PlankaCardMembershipCopyWith<$Res> {
  __$PlankaCardMembershipCopyWithImpl(this._self, this._then);

  final _PlankaCardMembership _self;
  final $Res Function(_PlankaCardMembership) _then;

/// Create a copy of PlankaCardMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? userId = null,}) {
  return _then(_PlankaCardMembership(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlankaProjectManager {

 String get id; String get projectId; String get userId;
/// Create a copy of PlankaProjectManager
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaProjectManagerCopyWith<PlankaProjectManager> get copyWith => _$PlankaProjectManagerCopyWithImpl<PlankaProjectManager>(this as PlankaProjectManager, _$identity);

  /// Serializes this PlankaProjectManager to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaProjectManager&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,userId);

@override
String toString() {
  return 'PlankaProjectManager(id: $id, projectId: $projectId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class $PlankaProjectManagerCopyWith<$Res>  {
  factory $PlankaProjectManagerCopyWith(PlankaProjectManager value, $Res Function(PlankaProjectManager) _then) = _$PlankaProjectManagerCopyWithImpl;
@useResult
$Res call({
 String id, String projectId, String userId
});




}
/// @nodoc
class _$PlankaProjectManagerCopyWithImpl<$Res>
    implements $PlankaProjectManagerCopyWith<$Res> {
  _$PlankaProjectManagerCopyWithImpl(this._self, this._then);

  final PlankaProjectManager _self;
  final $Res Function(PlankaProjectManager) _then;

/// Create a copy of PlankaProjectManager
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? userId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaProjectManager].
extension PlankaProjectManagerPatterns on PlankaProjectManager {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaProjectManager value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaProjectManager() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaProjectManager value)  $default,){
final _that = this;
switch (_that) {
case _PlankaProjectManager():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaProjectManager value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaProjectManager() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectId,  String userId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaProjectManager() when $default != null:
return $default(_that.id,_that.projectId,_that.userId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectId,  String userId)  $default,) {final _that = this;
switch (_that) {
case _PlankaProjectManager():
return $default(_that.id,_that.projectId,_that.userId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectId,  String userId)?  $default,) {final _that = this;
switch (_that) {
case _PlankaProjectManager() when $default != null:
return $default(_that.id,_that.projectId,_that.userId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaProjectManager implements PlankaProjectManager {
  const _PlankaProjectManager({required this.id, required this.projectId, required this.userId});
  factory _PlankaProjectManager.fromJson(Map<String, dynamic> json) => _$PlankaProjectManagerFromJson(json);

@override final  String id;
@override final  String projectId;
@override final  String userId;

/// Create a copy of PlankaProjectManager
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaProjectManagerCopyWith<_PlankaProjectManager> get copyWith => __$PlankaProjectManagerCopyWithImpl<_PlankaProjectManager>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaProjectManagerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaProjectManager&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.userId, userId) || other.userId == userId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,userId);

@override
String toString() {
  return 'PlankaProjectManager(id: $id, projectId: $projectId, userId: $userId)';
}


}

/// @nodoc
abstract mixin class _$PlankaProjectManagerCopyWith<$Res> implements $PlankaProjectManagerCopyWith<$Res> {
  factory _$PlankaProjectManagerCopyWith(_PlankaProjectManager value, $Res Function(_PlankaProjectManager) _then) = __$PlankaProjectManagerCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectId, String userId
});




}
/// @nodoc
class __$PlankaProjectManagerCopyWithImpl<$Res>
    implements _$PlankaProjectManagerCopyWith<$Res> {
  __$PlankaProjectManagerCopyWithImpl(this._self, this._then);

  final _PlankaProjectManager _self;
  final $Res Function(_PlankaProjectManager) _then;

/// Create a copy of PlankaProjectManager
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? userId = null,}) {
  return _then(_PlankaProjectManager(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlankaBoardMembership {

 String get id; String get boardId; String get userId; String get role;
/// Create a copy of PlankaBoardMembership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaBoardMembershipCopyWith<PlankaBoardMembership> get copyWith => _$PlankaBoardMembershipCopyWithImpl<PlankaBoardMembership>(this as PlankaBoardMembership, _$identity);

  /// Serializes this PlankaBoardMembership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaBoardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,userId,role);

@override
String toString() {
  return 'PlankaBoardMembership(id: $id, boardId: $boardId, userId: $userId, role: $role)';
}


}

/// @nodoc
abstract mixin class $PlankaBoardMembershipCopyWith<$Res>  {
  factory $PlankaBoardMembershipCopyWith(PlankaBoardMembership value, $Res Function(PlankaBoardMembership) _then) = _$PlankaBoardMembershipCopyWithImpl;
@useResult
$Res call({
 String id, String boardId, String userId, String role
});




}
/// @nodoc
class _$PlankaBoardMembershipCopyWithImpl<$Res>
    implements $PlankaBoardMembershipCopyWith<$Res> {
  _$PlankaBoardMembershipCopyWithImpl(this._self, this._then);

  final PlankaBoardMembership _self;
  final $Res Function(PlankaBoardMembership) _then;

/// Create a copy of PlankaBoardMembership
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


/// Adds pattern-matching-related methods to [PlankaBoardMembership].
extension PlankaBoardMembershipPatterns on PlankaBoardMembership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaBoardMembership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaBoardMembership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaBoardMembership value)  $default,){
final _that = this;
switch (_that) {
case _PlankaBoardMembership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaBoardMembership value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaBoardMembership() when $default != null:
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
case _PlankaBoardMembership() when $default != null:
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
case _PlankaBoardMembership():
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
case _PlankaBoardMembership() when $default != null:
return $default(_that.id,_that.boardId,_that.userId,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaBoardMembership implements PlankaBoardMembership {
  const _PlankaBoardMembership({required this.id, required this.boardId, required this.userId, required this.role});
  factory _PlankaBoardMembership.fromJson(Map<String, dynamic> json) => _$PlankaBoardMembershipFromJson(json);

@override final  String id;
@override final  String boardId;
@override final  String userId;
@override final  String role;

/// Create a copy of PlankaBoardMembership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaBoardMembershipCopyWith<_PlankaBoardMembership> get copyWith => __$PlankaBoardMembershipCopyWithImpl<_PlankaBoardMembership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaBoardMembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaBoardMembership&&(identical(other.id, id) || other.id == id)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,boardId,userId,role);

@override
String toString() {
  return 'PlankaBoardMembership(id: $id, boardId: $boardId, userId: $userId, role: $role)';
}


}

/// @nodoc
abstract mixin class _$PlankaBoardMembershipCopyWith<$Res> implements $PlankaBoardMembershipCopyWith<$Res> {
  factory _$PlankaBoardMembershipCopyWith(_PlankaBoardMembership value, $Res Function(_PlankaBoardMembership) _then) = __$PlankaBoardMembershipCopyWithImpl;
@override @useResult
$Res call({
 String id, String boardId, String userId, String role
});




}
/// @nodoc
class __$PlankaBoardMembershipCopyWithImpl<$Res>
    implements _$PlankaBoardMembershipCopyWith<$Res> {
  __$PlankaBoardMembershipCopyWithImpl(this._self, this._then);

  final _PlankaBoardMembership _self;
  final $Res Function(_PlankaBoardMembership) _then;

/// Create a copy of PlankaBoardMembership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? boardId = null,Object? userId = null,Object? role = null,}) {
  return _then(_PlankaBoardMembership(
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

 String get id; String get cardId; String get name;@JsonKey(fromJson: _toDouble) double? get position;/// Whether the web client draws this checklist on the card front. The
/// server omits the key rather than defaulting it, so null means "not on
/// the front".
 bool? get showOnFrontOfCard;/// When set, completed tasks are hidden from the card-front rendering.
 bool? get hideCompletedTasks;
/// Create a copy of PlankaTaskList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaTaskListCopyWith<PlankaTaskList> get copyWith => _$PlankaTaskListCopyWithImpl<PlankaTaskList>(this as PlankaTaskList, _$identity);

  /// Serializes this PlankaTaskList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaTaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.showOnFrontOfCard, showOnFrontOfCard) || other.showOnFrontOfCard == showOnFrontOfCard)&&(identical(other.hideCompletedTasks, hideCompletedTasks) || other.hideCompletedTasks == hideCompletedTasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,name,position,showOnFrontOfCard,hideCompletedTasks);

@override
String toString() {
  return 'PlankaTaskList(id: $id, cardId: $cardId, name: $name, position: $position, showOnFrontOfCard: $showOnFrontOfCard, hideCompletedTasks: $hideCompletedTasks)';
}


}

/// @nodoc
abstract mixin class $PlankaTaskListCopyWith<$Res>  {
  factory $PlankaTaskListCopyWith(PlankaTaskList value, $Res Function(PlankaTaskList) _then) = _$PlankaTaskListCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String name,@JsonKey(fromJson: _toDouble) double? position, bool? showOnFrontOfCard, bool? hideCompletedTasks
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? name = null,Object? position = freezed,Object? showOnFrontOfCard = freezed,Object? hideCompletedTasks = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,showOnFrontOfCard: freezed == showOnFrontOfCard ? _self.showOnFrontOfCard : showOnFrontOfCard // ignore: cast_nullable_to_non_nullable
as bool?,hideCompletedTasks: freezed == hideCompletedTasks ? _self.hideCompletedTasks : hideCompletedTasks // ignore: cast_nullable_to_non_nullable
as bool?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String name, @JsonKey(fromJson: _toDouble)  double? position,  bool? showOnFrontOfCard,  bool? hideCompletedTasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaTaskList() when $default != null:
return $default(_that.id,_that.cardId,_that.name,_that.position,_that.showOnFrontOfCard,_that.hideCompletedTasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String name, @JsonKey(fromJson: _toDouble)  double? position,  bool? showOnFrontOfCard,  bool? hideCompletedTasks)  $default,) {final _that = this;
switch (_that) {
case _PlankaTaskList():
return $default(_that.id,_that.cardId,_that.name,_that.position,_that.showOnFrontOfCard,_that.hideCompletedTasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String name, @JsonKey(fromJson: _toDouble)  double? position,  bool? showOnFrontOfCard,  bool? hideCompletedTasks)?  $default,) {final _that = this;
switch (_that) {
case _PlankaTaskList() when $default != null:
return $default(_that.id,_that.cardId,_that.name,_that.position,_that.showOnFrontOfCard,_that.hideCompletedTasks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaTaskList implements PlankaTaskList {
  const _PlankaTaskList({required this.id, required this.cardId, required this.name, @JsonKey(fromJson: _toDouble) this.position, this.showOnFrontOfCard, this.hideCompletedTasks});
  factory _PlankaTaskList.fromJson(Map<String, dynamic> json) => _$PlankaTaskListFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String name;
@override@JsonKey(fromJson: _toDouble) final  double? position;
/// Whether the web client draws this checklist on the card front. The
/// server omits the key rather than defaulting it, so null means "not on
/// the front".
@override final  bool? showOnFrontOfCard;
/// When set, completed tasks are hidden from the card-front rendering.
@override final  bool? hideCompletedTasks;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaTaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&(identical(other.showOnFrontOfCard, showOnFrontOfCard) || other.showOnFrontOfCard == showOnFrontOfCard)&&(identical(other.hideCompletedTasks, hideCompletedTasks) || other.hideCompletedTasks == hideCompletedTasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,name,position,showOnFrontOfCard,hideCompletedTasks);

@override
String toString() {
  return 'PlankaTaskList(id: $id, cardId: $cardId, name: $name, position: $position, showOnFrontOfCard: $showOnFrontOfCard, hideCompletedTasks: $hideCompletedTasks)';
}


}

/// @nodoc
abstract mixin class _$PlankaTaskListCopyWith<$Res> implements $PlankaTaskListCopyWith<$Res> {
  factory _$PlankaTaskListCopyWith(_PlankaTaskList value, $Res Function(_PlankaTaskList) _then) = __$PlankaTaskListCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String name,@JsonKey(fromJson: _toDouble) double? position, bool? showOnFrontOfCard, bool? hideCompletedTasks
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? name = null,Object? position = freezed,Object? showOnFrontOfCard = freezed,Object? hideCompletedTasks = freezed,}) {
  return _then(_PlankaTaskList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,showOnFrontOfCard: freezed == showOnFrontOfCard ? _self.showOnFrontOfCard : showOnFrontOfCard // ignore: cast_nullable_to_non_nullable
as bool?,hideCompletedTasks: freezed == hideCompletedTasks ? _self.hideCompletedTasks : hideCompletedTasks // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$PlankaTask {

 String get id; String get taskListId; String get name; bool get isCompleted;@JsonKey(fromJson: _toDouble) double? get position;/// The board member assigned to this item, if any.
 String? get assigneeUserId;/// When set, the item mirrors a card: its name is that card's and its
/// completion state comes from the card's [PlankaCard.isClosed], not from
/// [isCompleted] here.
 String? get linkedCardId;
/// Create a copy of PlankaTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaTaskCopyWith<PlankaTask> get copyWith => _$PlankaTaskCopyWithImpl<PlankaTask>(this as PlankaTask, _$identity);

  /// Serializes this PlankaTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaTask&&(identical(other.id, id) || other.id == id)&&(identical(other.taskListId, taskListId) || other.taskListId == taskListId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.position, position) || other.position == position)&&(identical(other.assigneeUserId, assigneeUserId) || other.assigneeUserId == assigneeUserId)&&(identical(other.linkedCardId, linkedCardId) || other.linkedCardId == linkedCardId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskListId,name,isCompleted,position,assigneeUserId,linkedCardId);

@override
String toString() {
  return 'PlankaTask(id: $id, taskListId: $taskListId, name: $name, isCompleted: $isCompleted, position: $position, assigneeUserId: $assigneeUserId, linkedCardId: $linkedCardId)';
}


}

/// @nodoc
abstract mixin class $PlankaTaskCopyWith<$Res>  {
  factory $PlankaTaskCopyWith(PlankaTask value, $Res Function(PlankaTask) _then) = _$PlankaTaskCopyWithImpl;
@useResult
$Res call({
 String id, String taskListId, String name, bool isCompleted,@JsonKey(fromJson: _toDouble) double? position, String? assigneeUserId, String? linkedCardId
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskListId = null,Object? name = null,Object? isCompleted = null,Object? position = freezed,Object? assigneeUserId = freezed,Object? linkedCardId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskListId: null == taskListId ? _self.taskListId : taskListId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,assigneeUserId: freezed == assigneeUserId ? _self.assigneeUserId : assigneeUserId // ignore: cast_nullable_to_non_nullable
as String?,linkedCardId: freezed == linkedCardId ? _self.linkedCardId : linkedCardId // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskListId,  String name,  bool isCompleted, @JsonKey(fromJson: _toDouble)  double? position,  String? assigneeUserId,  String? linkedCardId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaTask() when $default != null:
return $default(_that.id,_that.taskListId,_that.name,_that.isCompleted,_that.position,_that.assigneeUserId,_that.linkedCardId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskListId,  String name,  bool isCompleted, @JsonKey(fromJson: _toDouble)  double? position,  String? assigneeUserId,  String? linkedCardId)  $default,) {final _that = this;
switch (_that) {
case _PlankaTask():
return $default(_that.id,_that.taskListId,_that.name,_that.isCompleted,_that.position,_that.assigneeUserId,_that.linkedCardId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskListId,  String name,  bool isCompleted, @JsonKey(fromJson: _toDouble)  double? position,  String? assigneeUserId,  String? linkedCardId)?  $default,) {final _that = this;
switch (_that) {
case _PlankaTask() when $default != null:
return $default(_that.id,_that.taskListId,_that.name,_that.isCompleted,_that.position,_that.assigneeUserId,_that.linkedCardId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaTask implements PlankaTask {
  const _PlankaTask({required this.id, required this.taskListId, required this.name, required this.isCompleted, @JsonKey(fromJson: _toDouble) this.position, this.assigneeUserId, this.linkedCardId});
  factory _PlankaTask.fromJson(Map<String, dynamic> json) => _$PlankaTaskFromJson(json);

@override final  String id;
@override final  String taskListId;
@override final  String name;
@override final  bool isCompleted;
@override@JsonKey(fromJson: _toDouble) final  double? position;
/// The board member assigned to this item, if any.
@override final  String? assigneeUserId;
/// When set, the item mirrors a card: its name is that card's and its
/// completion state comes from the card's [PlankaCard.isClosed], not from
/// [isCompleted] here.
@override final  String? linkedCardId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaTask&&(identical(other.id, id) || other.id == id)&&(identical(other.taskListId, taskListId) || other.taskListId == taskListId)&&(identical(other.name, name) || other.name == name)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.position, position) || other.position == position)&&(identical(other.assigneeUserId, assigneeUserId) || other.assigneeUserId == assigneeUserId)&&(identical(other.linkedCardId, linkedCardId) || other.linkedCardId == linkedCardId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,taskListId,name,isCompleted,position,assigneeUserId,linkedCardId);

@override
String toString() {
  return 'PlankaTask(id: $id, taskListId: $taskListId, name: $name, isCompleted: $isCompleted, position: $position, assigneeUserId: $assigneeUserId, linkedCardId: $linkedCardId)';
}


}

/// @nodoc
abstract mixin class _$PlankaTaskCopyWith<$Res> implements $PlankaTaskCopyWith<$Res> {
  factory _$PlankaTaskCopyWith(_PlankaTask value, $Res Function(_PlankaTask) _then) = __$PlankaTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskListId, String name, bool isCompleted,@JsonKey(fromJson: _toDouble) double? position, String? assigneeUserId, String? linkedCardId
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskListId = null,Object? name = null,Object? isCompleted = null,Object? position = freezed,Object? assigneeUserId = freezed,Object? linkedCardId = freezed,}) {
  return _then(_PlankaTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskListId: null == taskListId ? _self.taskListId : taskListId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,assigneeUserId: freezed == assigneeUserId ? _self.assigneeUserId : assigneeUserId // ignore: cast_nullable_to_non_nullable
as String?,linkedCardId: freezed == linkedCardId ? _self.linkedCardId : linkedCardId // ignore: cast_nullable_to_non_nullable
as String?,
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
mixin _$PlankaCustomFieldGroup {

 String get id; String? get name; String? get boardId; String? get cardId; String? get baseCustomFieldGroupId;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCustomFieldGroupCopyWith<PlankaCustomFieldGroup> get copyWith => _$PlankaCustomFieldGroupCopyWithImpl<PlankaCustomFieldGroup>(this as PlankaCustomFieldGroup, _$identity);

  /// Serializes this PlankaCustomFieldGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCustomFieldGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.baseCustomFieldGroupId, baseCustomFieldGroupId) || other.baseCustomFieldGroupId == baseCustomFieldGroupId)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,boardId,cardId,baseCustomFieldGroupId,position);

@override
String toString() {
  return 'PlankaCustomFieldGroup(id: $id, name: $name, boardId: $boardId, cardId: $cardId, baseCustomFieldGroupId: $baseCustomFieldGroupId, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaCustomFieldGroupCopyWith<$Res>  {
  factory $PlankaCustomFieldGroupCopyWith(PlankaCustomFieldGroup value, $Res Function(PlankaCustomFieldGroup) _then) = _$PlankaCustomFieldGroupCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? boardId, String? cardId, String? baseCustomFieldGroupId,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaCustomFieldGroupCopyWithImpl<$Res>
    implements $PlankaCustomFieldGroupCopyWith<$Res> {
  _$PlankaCustomFieldGroupCopyWithImpl(this._self, this._then);

  final PlankaCustomFieldGroup _self;
  final $Res Function(PlankaCustomFieldGroup) _then;

/// Create a copy of PlankaCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? boardId = freezed,Object? cardId = freezed,Object? baseCustomFieldGroupId = freezed,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,boardId: freezed == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String?,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,baseCustomFieldGroupId: freezed == baseCustomFieldGroupId ? _self.baseCustomFieldGroupId : baseCustomFieldGroupId // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaCustomFieldGroup].
extension PlankaCustomFieldGroupPatterns on PlankaCustomFieldGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaCustomFieldGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaCustomFieldGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaCustomFieldGroup value)  $default,){
final _that = this;
switch (_that) {
case _PlankaCustomFieldGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaCustomFieldGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaCustomFieldGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? boardId,  String? cardId,  String? baseCustomFieldGroupId, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaCustomFieldGroup() when $default != null:
return $default(_that.id,_that.name,_that.boardId,_that.cardId,_that.baseCustomFieldGroupId,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? boardId,  String? cardId,  String? baseCustomFieldGroupId, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaCustomFieldGroup():
return $default(_that.id,_that.name,_that.boardId,_that.cardId,_that.baseCustomFieldGroupId,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? boardId,  String? cardId,  String? baseCustomFieldGroupId, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaCustomFieldGroup() when $default != null:
return $default(_that.id,_that.name,_that.boardId,_that.cardId,_that.baseCustomFieldGroupId,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCustomFieldGroup implements PlankaCustomFieldGroup {
  const _PlankaCustomFieldGroup({required this.id, this.name, this.boardId, this.cardId, this.baseCustomFieldGroupId, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaCustomFieldGroup.fromJson(Map<String, dynamic> json) => _$PlankaCustomFieldGroupFromJson(json);

@override final  String id;
@override final  String? name;
@override final  String? boardId;
@override final  String? cardId;
@override final  String? baseCustomFieldGroupId;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCustomFieldGroupCopyWith<_PlankaCustomFieldGroup> get copyWith => __$PlankaCustomFieldGroupCopyWithImpl<_PlankaCustomFieldGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCustomFieldGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCustomFieldGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.baseCustomFieldGroupId, baseCustomFieldGroupId) || other.baseCustomFieldGroupId == baseCustomFieldGroupId)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,boardId,cardId,baseCustomFieldGroupId,position);

@override
String toString() {
  return 'PlankaCustomFieldGroup(id: $id, name: $name, boardId: $boardId, cardId: $cardId, baseCustomFieldGroupId: $baseCustomFieldGroupId, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaCustomFieldGroupCopyWith<$Res> implements $PlankaCustomFieldGroupCopyWith<$Res> {
  factory _$PlankaCustomFieldGroupCopyWith(_PlankaCustomFieldGroup value, $Res Function(_PlankaCustomFieldGroup) _then) = __$PlankaCustomFieldGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? boardId, String? cardId, String? baseCustomFieldGroupId,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaCustomFieldGroupCopyWithImpl<$Res>
    implements _$PlankaCustomFieldGroupCopyWith<$Res> {
  __$PlankaCustomFieldGroupCopyWithImpl(this._self, this._then);

  final _PlankaCustomFieldGroup _self;
  final $Res Function(_PlankaCustomFieldGroup) _then;

/// Create a copy of PlankaCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? boardId = freezed,Object? cardId = freezed,Object? baseCustomFieldGroupId = freezed,Object? position = freezed,}) {
  return _then(_PlankaCustomFieldGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,boardId: freezed == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String?,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,baseCustomFieldGroupId: freezed == baseCustomFieldGroupId ? _self.baseCustomFieldGroupId : baseCustomFieldGroupId // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlankaBaseCustomFieldGroup {

 String get id; String get projectId; String? get name;
/// Create a copy of PlankaBaseCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaBaseCustomFieldGroupCopyWith<PlankaBaseCustomFieldGroup> get copyWith => _$PlankaBaseCustomFieldGroupCopyWithImpl<PlankaBaseCustomFieldGroup>(this as PlankaBaseCustomFieldGroup, _$identity);

  /// Serializes this PlankaBaseCustomFieldGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaBaseCustomFieldGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,name);

@override
String toString() {
  return 'PlankaBaseCustomFieldGroup(id: $id, projectId: $projectId, name: $name)';
}


}

/// @nodoc
abstract mixin class $PlankaBaseCustomFieldGroupCopyWith<$Res>  {
  factory $PlankaBaseCustomFieldGroupCopyWith(PlankaBaseCustomFieldGroup value, $Res Function(PlankaBaseCustomFieldGroup) _then) = _$PlankaBaseCustomFieldGroupCopyWithImpl;
@useResult
$Res call({
 String id, String projectId, String? name
});




}
/// @nodoc
class _$PlankaBaseCustomFieldGroupCopyWithImpl<$Res>
    implements $PlankaBaseCustomFieldGroupCopyWith<$Res> {
  _$PlankaBaseCustomFieldGroupCopyWithImpl(this._self, this._then);

  final PlankaBaseCustomFieldGroup _self;
  final $Res Function(PlankaBaseCustomFieldGroup) _then;

/// Create a copy of PlankaBaseCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaBaseCustomFieldGroup].
extension PlankaBaseCustomFieldGroupPatterns on PlankaBaseCustomFieldGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaBaseCustomFieldGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaBaseCustomFieldGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaBaseCustomFieldGroup value)  $default,){
final _that = this;
switch (_that) {
case _PlankaBaseCustomFieldGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaBaseCustomFieldGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaBaseCustomFieldGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectId,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaBaseCustomFieldGroup() when $default != null:
return $default(_that.id,_that.projectId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectId,  String? name)  $default,) {final _that = this;
switch (_that) {
case _PlankaBaseCustomFieldGroup():
return $default(_that.id,_that.projectId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectId,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _PlankaBaseCustomFieldGroup() when $default != null:
return $default(_that.id,_that.projectId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaBaseCustomFieldGroup implements PlankaBaseCustomFieldGroup {
  const _PlankaBaseCustomFieldGroup({required this.id, required this.projectId, this.name});
  factory _PlankaBaseCustomFieldGroup.fromJson(Map<String, dynamic> json) => _$PlankaBaseCustomFieldGroupFromJson(json);

@override final  String id;
@override final  String projectId;
@override final  String? name;

/// Create a copy of PlankaBaseCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaBaseCustomFieldGroupCopyWith<_PlankaBaseCustomFieldGroup> get copyWith => __$PlankaBaseCustomFieldGroupCopyWithImpl<_PlankaBaseCustomFieldGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaBaseCustomFieldGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaBaseCustomFieldGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,name);

@override
String toString() {
  return 'PlankaBaseCustomFieldGroup(id: $id, projectId: $projectId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PlankaBaseCustomFieldGroupCopyWith<$Res> implements $PlankaBaseCustomFieldGroupCopyWith<$Res> {
  factory _$PlankaBaseCustomFieldGroupCopyWith(_PlankaBaseCustomFieldGroup value, $Res Function(_PlankaBaseCustomFieldGroup) _then) = __$PlankaBaseCustomFieldGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectId, String? name
});




}
/// @nodoc
class __$PlankaBaseCustomFieldGroupCopyWithImpl<$Res>
    implements _$PlankaBaseCustomFieldGroupCopyWith<$Res> {
  __$PlankaBaseCustomFieldGroupCopyWithImpl(this._self, this._then);

  final _PlankaBaseCustomFieldGroup _self;
  final $Res Function(_PlankaBaseCustomFieldGroup) _then;

/// Create a copy of PlankaBaseCustomFieldGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? name = freezed,}) {
  return _then(_PlankaBaseCustomFieldGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlankaCustomField {

 String get id; String get name; String? get customFieldGroupId; String? get baseCustomFieldGroupId; bool? get showOnFrontOfCard;@JsonKey(fromJson: _toDouble) double? get position;
/// Create a copy of PlankaCustomField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCustomFieldCopyWith<PlankaCustomField> get copyWith => _$PlankaCustomFieldCopyWithImpl<PlankaCustomField>(this as PlankaCustomField, _$identity);

  /// Serializes this PlankaCustomField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCustomField&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.customFieldGroupId, customFieldGroupId) || other.customFieldGroupId == customFieldGroupId)&&(identical(other.baseCustomFieldGroupId, baseCustomFieldGroupId) || other.baseCustomFieldGroupId == baseCustomFieldGroupId)&&(identical(other.showOnFrontOfCard, showOnFrontOfCard) || other.showOnFrontOfCard == showOnFrontOfCard)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,customFieldGroupId,baseCustomFieldGroupId,showOnFrontOfCard,position);

@override
String toString() {
  return 'PlankaCustomField(id: $id, name: $name, customFieldGroupId: $customFieldGroupId, baseCustomFieldGroupId: $baseCustomFieldGroupId, showOnFrontOfCard: $showOnFrontOfCard, position: $position)';
}


}

/// @nodoc
abstract mixin class $PlankaCustomFieldCopyWith<$Res>  {
  factory $PlankaCustomFieldCopyWith(PlankaCustomField value, $Res Function(PlankaCustomField) _then) = _$PlankaCustomFieldCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? customFieldGroupId, String? baseCustomFieldGroupId, bool? showOnFrontOfCard,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class _$PlankaCustomFieldCopyWithImpl<$Res>
    implements $PlankaCustomFieldCopyWith<$Res> {
  _$PlankaCustomFieldCopyWithImpl(this._self, this._then);

  final PlankaCustomField _self;
  final $Res Function(PlankaCustomField) _then;

/// Create a copy of PlankaCustomField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? customFieldGroupId = freezed,Object? baseCustomFieldGroupId = freezed,Object? showOnFrontOfCard = freezed,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,customFieldGroupId: freezed == customFieldGroupId ? _self.customFieldGroupId : customFieldGroupId // ignore: cast_nullable_to_non_nullable
as String?,baseCustomFieldGroupId: freezed == baseCustomFieldGroupId ? _self.baseCustomFieldGroupId : baseCustomFieldGroupId // ignore: cast_nullable_to_non_nullable
as String?,showOnFrontOfCard: freezed == showOnFrontOfCard ? _self.showOnFrontOfCard : showOnFrontOfCard // ignore: cast_nullable_to_non_nullable
as bool?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaCustomField].
extension PlankaCustomFieldPatterns on PlankaCustomField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaCustomField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaCustomField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaCustomField value)  $default,){
final _that = this;
switch (_that) {
case _PlankaCustomField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaCustomField value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaCustomField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? customFieldGroupId,  String? baseCustomFieldGroupId,  bool? showOnFrontOfCard, @JsonKey(fromJson: _toDouble)  double? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaCustomField() when $default != null:
return $default(_that.id,_that.name,_that.customFieldGroupId,_that.baseCustomFieldGroupId,_that.showOnFrontOfCard,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? customFieldGroupId,  String? baseCustomFieldGroupId,  bool? showOnFrontOfCard, @JsonKey(fromJson: _toDouble)  double? position)  $default,) {final _that = this;
switch (_that) {
case _PlankaCustomField():
return $default(_that.id,_that.name,_that.customFieldGroupId,_that.baseCustomFieldGroupId,_that.showOnFrontOfCard,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? customFieldGroupId,  String? baseCustomFieldGroupId,  bool? showOnFrontOfCard, @JsonKey(fromJson: _toDouble)  double? position)?  $default,) {final _that = this;
switch (_that) {
case _PlankaCustomField() when $default != null:
return $default(_that.id,_that.name,_that.customFieldGroupId,_that.baseCustomFieldGroupId,_that.showOnFrontOfCard,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCustomField implements PlankaCustomField {
  const _PlankaCustomField({required this.id, required this.name, this.customFieldGroupId, this.baseCustomFieldGroupId, this.showOnFrontOfCard, @JsonKey(fromJson: _toDouble) this.position});
  factory _PlankaCustomField.fromJson(Map<String, dynamic> json) => _$PlankaCustomFieldFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? customFieldGroupId;
@override final  String? baseCustomFieldGroupId;
@override final  bool? showOnFrontOfCard;
@override@JsonKey(fromJson: _toDouble) final  double? position;

/// Create a copy of PlankaCustomField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCustomFieldCopyWith<_PlankaCustomField> get copyWith => __$PlankaCustomFieldCopyWithImpl<_PlankaCustomField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCustomFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCustomField&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.customFieldGroupId, customFieldGroupId) || other.customFieldGroupId == customFieldGroupId)&&(identical(other.baseCustomFieldGroupId, baseCustomFieldGroupId) || other.baseCustomFieldGroupId == baseCustomFieldGroupId)&&(identical(other.showOnFrontOfCard, showOnFrontOfCard) || other.showOnFrontOfCard == showOnFrontOfCard)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,customFieldGroupId,baseCustomFieldGroupId,showOnFrontOfCard,position);

@override
String toString() {
  return 'PlankaCustomField(id: $id, name: $name, customFieldGroupId: $customFieldGroupId, baseCustomFieldGroupId: $baseCustomFieldGroupId, showOnFrontOfCard: $showOnFrontOfCard, position: $position)';
}


}

/// @nodoc
abstract mixin class _$PlankaCustomFieldCopyWith<$Res> implements $PlankaCustomFieldCopyWith<$Res> {
  factory _$PlankaCustomFieldCopyWith(_PlankaCustomField value, $Res Function(_PlankaCustomField) _then) = __$PlankaCustomFieldCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? customFieldGroupId, String? baseCustomFieldGroupId, bool? showOnFrontOfCard,@JsonKey(fromJson: _toDouble) double? position
});




}
/// @nodoc
class __$PlankaCustomFieldCopyWithImpl<$Res>
    implements _$PlankaCustomFieldCopyWith<$Res> {
  __$PlankaCustomFieldCopyWithImpl(this._self, this._then);

  final _PlankaCustomField _self;
  final $Res Function(_PlankaCustomField) _then;

/// Create a copy of PlankaCustomField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? customFieldGroupId = freezed,Object? baseCustomFieldGroupId = freezed,Object? showOnFrontOfCard = freezed,Object? position = freezed,}) {
  return _then(_PlankaCustomField(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,customFieldGroupId: freezed == customFieldGroupId ? _self.customFieldGroupId : customFieldGroupId // ignore: cast_nullable_to_non_nullable
as String?,baseCustomFieldGroupId: freezed == baseCustomFieldGroupId ? _self.baseCustomFieldGroupId : baseCustomFieldGroupId // ignore: cast_nullable_to_non_nullable
as String?,showOnFrontOfCard: freezed == showOnFrontOfCard ? _self.showOnFrontOfCard : showOnFrontOfCard // ignore: cast_nullable_to_non_nullable
as bool?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlankaCustomFieldValue {

 String get id; String get cardId; String get customFieldGroupId; String get customFieldId; String get content;
/// Create a copy of PlankaCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaCustomFieldValueCopyWith<PlankaCustomFieldValue> get copyWith => _$PlankaCustomFieldValueCopyWithImpl<PlankaCustomFieldValue>(this as PlankaCustomFieldValue, _$identity);

  /// Serializes this PlankaCustomFieldValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaCustomFieldValue&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.customFieldGroupId, customFieldGroupId) || other.customFieldGroupId == customFieldGroupId)&&(identical(other.customFieldId, customFieldId) || other.customFieldId == customFieldId)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,customFieldGroupId,customFieldId,content);

@override
String toString() {
  return 'PlankaCustomFieldValue(id: $id, cardId: $cardId, customFieldGroupId: $customFieldGroupId, customFieldId: $customFieldId, content: $content)';
}


}

/// @nodoc
abstract mixin class $PlankaCustomFieldValueCopyWith<$Res>  {
  factory $PlankaCustomFieldValueCopyWith(PlankaCustomFieldValue value, $Res Function(PlankaCustomFieldValue) _then) = _$PlankaCustomFieldValueCopyWithImpl;
@useResult
$Res call({
 String id, String cardId, String customFieldGroupId, String customFieldId, String content
});




}
/// @nodoc
class _$PlankaCustomFieldValueCopyWithImpl<$Res>
    implements $PlankaCustomFieldValueCopyWith<$Res> {
  _$PlankaCustomFieldValueCopyWithImpl(this._self, this._then);

  final PlankaCustomFieldValue _self;
  final $Res Function(PlankaCustomFieldValue) _then;

/// Create a copy of PlankaCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? customFieldGroupId = null,Object? customFieldId = null,Object? content = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,customFieldGroupId: null == customFieldGroupId ? _self.customFieldGroupId : customFieldGroupId // ignore: cast_nullable_to_non_nullable
as String,customFieldId: null == customFieldId ? _self.customFieldId : customFieldId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaCustomFieldValue].
extension PlankaCustomFieldValuePatterns on PlankaCustomFieldValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaCustomFieldValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaCustomFieldValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaCustomFieldValue value)  $default,){
final _that = this;
switch (_that) {
case _PlankaCustomFieldValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaCustomFieldValue value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaCustomFieldValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId,  String customFieldGroupId,  String customFieldId,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaCustomFieldValue() when $default != null:
return $default(_that.id,_that.cardId,_that.customFieldGroupId,_that.customFieldId,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId,  String customFieldGroupId,  String customFieldId,  String content)  $default,) {final _that = this;
switch (_that) {
case _PlankaCustomFieldValue():
return $default(_that.id,_that.cardId,_that.customFieldGroupId,_that.customFieldId,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId,  String customFieldGroupId,  String customFieldId,  String content)?  $default,) {final _that = this;
switch (_that) {
case _PlankaCustomFieldValue() when $default != null:
return $default(_that.id,_that.cardId,_that.customFieldGroupId,_that.customFieldId,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaCustomFieldValue implements PlankaCustomFieldValue {
  const _PlankaCustomFieldValue({required this.id, required this.cardId, required this.customFieldGroupId, required this.customFieldId, required this.content});
  factory _PlankaCustomFieldValue.fromJson(Map<String, dynamic> json) => _$PlankaCustomFieldValueFromJson(json);

@override final  String id;
@override final  String cardId;
@override final  String customFieldGroupId;
@override final  String customFieldId;
@override final  String content;

/// Create a copy of PlankaCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaCustomFieldValueCopyWith<_PlankaCustomFieldValue> get copyWith => __$PlankaCustomFieldValueCopyWithImpl<_PlankaCustomFieldValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaCustomFieldValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaCustomFieldValue&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.customFieldGroupId, customFieldGroupId) || other.customFieldGroupId == customFieldGroupId)&&(identical(other.customFieldId, customFieldId) || other.customFieldId == customFieldId)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,customFieldGroupId,customFieldId,content);

@override
String toString() {
  return 'PlankaCustomFieldValue(id: $id, cardId: $cardId, customFieldGroupId: $customFieldGroupId, customFieldId: $customFieldId, content: $content)';
}


}

/// @nodoc
abstract mixin class _$PlankaCustomFieldValueCopyWith<$Res> implements $PlankaCustomFieldValueCopyWith<$Res> {
  factory _$PlankaCustomFieldValueCopyWith(_PlankaCustomFieldValue value, $Res Function(_PlankaCustomFieldValue) _then) = __$PlankaCustomFieldValueCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId, String customFieldGroupId, String customFieldId, String content
});




}
/// @nodoc
class __$PlankaCustomFieldValueCopyWithImpl<$Res>
    implements _$PlankaCustomFieldValueCopyWith<$Res> {
  __$PlankaCustomFieldValueCopyWithImpl(this._self, this._then);

  final _PlankaCustomFieldValue _self;
  final $Res Function(_PlankaCustomFieldValue) _then;

/// Create a copy of PlankaCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? customFieldGroupId = null,Object? customFieldId = null,Object? content = null,}) {
  return _then(_PlankaCustomFieldValue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,customFieldGroupId: null == customFieldGroupId ? _self.customFieldGroupId : customFieldGroupId // ignore: cast_nullable_to_non_nullable
as String,customFieldId: null == customFieldId ? _self.customFieldId : customFieldId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlankaAction {

 String get id; String get cardId;@JsonKey(unknownEnumValue: PlankaActionType.unknown) PlankaActionType get type; String? get userId; Map<String, dynamic>? get data; DateTime? get createdAt;
/// Create a copy of PlankaAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlankaActionCopyWith<PlankaAction> get copyWith => _$PlankaActionCopyWithImpl<PlankaAction>(this as PlankaAction, _$identity);

  /// Serializes this PlankaAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlankaAction&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,type,userId,const DeepCollectionEquality().hash(data),createdAt);

@override
String toString() {
  return 'PlankaAction(id: $id, cardId: $cardId, type: $type, userId: $userId, data: $data, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlankaActionCopyWith<$Res>  {
  factory $PlankaActionCopyWith(PlankaAction value, $Res Function(PlankaAction) _then) = _$PlankaActionCopyWithImpl;
@useResult
$Res call({
 String id, String cardId,@JsonKey(unknownEnumValue: PlankaActionType.unknown) PlankaActionType type, String? userId, Map<String, dynamic>? data, DateTime? createdAt
});




}
/// @nodoc
class _$PlankaActionCopyWithImpl<$Res>
    implements $PlankaActionCopyWith<$Res> {
  _$PlankaActionCopyWithImpl(this._self, this._then);

  final PlankaAction _self;
  final $Res Function(PlankaAction) _then;

/// Create a copy of PlankaAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cardId = null,Object? type = null,Object? userId = freezed,Object? data = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlankaActionType,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlankaAction].
extension PlankaActionPatterns on PlankaAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlankaAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlankaAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlankaAction value)  $default,){
final _that = this;
switch (_that) {
case _PlankaAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlankaAction value)?  $default,){
final _that = this;
switch (_that) {
case _PlankaAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String cardId, @JsonKey(unknownEnumValue: PlankaActionType.unknown)  PlankaActionType type,  String? userId,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlankaAction() when $default != null:
return $default(_that.id,_that.cardId,_that.type,_that.userId,_that.data,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String cardId, @JsonKey(unknownEnumValue: PlankaActionType.unknown)  PlankaActionType type,  String? userId,  Map<String, dynamic>? data,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PlankaAction():
return $default(_that.id,_that.cardId,_that.type,_that.userId,_that.data,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String cardId, @JsonKey(unknownEnumValue: PlankaActionType.unknown)  PlankaActionType type,  String? userId,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PlankaAction() when $default != null:
return $default(_that.id,_that.cardId,_that.type,_that.userId,_that.data,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlankaAction implements PlankaAction {
  const _PlankaAction({required this.id, required this.cardId, @JsonKey(unknownEnumValue: PlankaActionType.unknown) required this.type, this.userId, final  Map<String, dynamic>? data, this.createdAt}): _data = data;
  factory _PlankaAction.fromJson(Map<String, dynamic> json) => _$PlankaActionFromJson(json);

@override final  String id;
@override final  String cardId;
@override@JsonKey(unknownEnumValue: PlankaActionType.unknown) final  PlankaActionType type;
@override final  String? userId;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? createdAt;

/// Create a copy of PlankaAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlankaActionCopyWith<_PlankaAction> get copyWith => __$PlankaActionCopyWithImpl<_PlankaAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlankaActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlankaAction&&(identical(other.id, id) || other.id == id)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.type, type) || other.type == type)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cardId,type,userId,const DeepCollectionEquality().hash(_data),createdAt);

@override
String toString() {
  return 'PlankaAction(id: $id, cardId: $cardId, type: $type, userId: $userId, data: $data, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlankaActionCopyWith<$Res> implements $PlankaActionCopyWith<$Res> {
  factory _$PlankaActionCopyWith(_PlankaAction value, $Res Function(_PlankaAction) _then) = __$PlankaActionCopyWithImpl;
@override @useResult
$Res call({
 String id, String cardId,@JsonKey(unknownEnumValue: PlankaActionType.unknown) PlankaActionType type, String? userId, Map<String, dynamic>? data, DateTime? createdAt
});




}
/// @nodoc
class __$PlankaActionCopyWithImpl<$Res>
    implements _$PlankaActionCopyWith<$Res> {
  __$PlankaActionCopyWithImpl(this._self, this._then);

  final _PlankaAction _self;
  final $Res Function(_PlankaAction) _then;

/// Create a copy of PlankaAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cardId = null,Object? type = null,Object? userId = freezed,Object? data = freezed,Object? createdAt = freezed,}) {
  return _then(_PlankaAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PlankaActionType,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PlankaNotification {

 String get id; String get userId;@JsonKey(unknownEnumValue: PlankaNotificationType.unknown) PlankaNotificationType get type; bool get isRead; String? get cardId; Map<String, dynamic>? get data; DateTime? get createdAt;
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
 String id, String userId,@JsonKey(unknownEnumValue: PlankaNotificationType.unknown) PlankaNotificationType type, bool isRead, String? cardId, Map<String, dynamic>? data, DateTime? createdAt
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
as PlankaNotificationType,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId, @JsonKey(unknownEnumValue: PlankaNotificationType.unknown)  PlankaNotificationType type,  bool isRead,  String? cardId,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId, @JsonKey(unknownEnumValue: PlankaNotificationType.unknown)  PlankaNotificationType type,  bool isRead,  String? cardId,  Map<String, dynamic>? data,  DateTime? createdAt)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId, @JsonKey(unknownEnumValue: PlankaNotificationType.unknown)  PlankaNotificationType type,  bool isRead,  String? cardId,  Map<String, dynamic>? data,  DateTime? createdAt)?  $default,) {final _that = this;
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
  const _PlankaNotification({required this.id, required this.userId, @JsonKey(unknownEnumValue: PlankaNotificationType.unknown) required this.type, required this.isRead, this.cardId, final  Map<String, dynamic>? data, this.createdAt}): _data = data;
  factory _PlankaNotification.fromJson(Map<String, dynamic> json) => _$PlankaNotificationFromJson(json);

@override final  String id;
@override final  String userId;
@override@JsonKey(unknownEnumValue: PlankaNotificationType.unknown) final  PlankaNotificationType type;
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
 String id, String userId,@JsonKey(unknownEnumValue: PlankaNotificationType.unknown) PlankaNotificationType type, bool isRead, String? cardId, Map<String, dynamic>? data, DateTime? createdAt
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
as PlankaNotificationType,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
