// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 int get id; String get username; String get email; String? get displayName; String? get avatarUrl; int? get tgUserId; bool get isActive; String get role;// createFactory: false をやめ、@JsonKey のコンバータで特殊パースを実現
@JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson) List<String> get permissions; int get aiQuotaMonthly; int get aiQuotaUsed;@JsonKey(fromJson: numToDouble) double get aiQuotaResetAt;@JsonKey(fromJson: numToDouble) double get createdAt;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.tgUserId, tgUserId) || other.tgUserId == tgUserId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.aiQuotaMonthly, aiQuotaMonthly) || other.aiQuotaMonthly == aiQuotaMonthly)&&(identical(other.aiQuotaUsed, aiQuotaUsed) || other.aiQuotaUsed == aiQuotaUsed)&&(identical(other.aiQuotaResetAt, aiQuotaResetAt) || other.aiQuotaResetAt == aiQuotaResetAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,email,displayName,avatarUrl,tgUserId,isActive,role,const DeepCollectionEquality().hash(permissions),aiQuotaMonthly,aiQuotaUsed,aiQuotaResetAt,createdAt);

@override
String toString() {
  return 'UserProfile(id: $id, username: $username, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, tgUserId: $tgUserId, isActive: $isActive, role: $role, permissions: $permissions, aiQuotaMonthly: $aiQuotaMonthly, aiQuotaUsed: $aiQuotaUsed, aiQuotaResetAt: $aiQuotaResetAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 int id, String username, String email, String? displayName, String? avatarUrl, int? tgUserId, bool isActive, String role,@JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson) List<String> permissions, int aiQuotaMonthly, int aiQuotaUsed,@JsonKey(fromJson: numToDouble) double aiQuotaResetAt,@JsonKey(fromJson: numToDouble) double createdAt
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? email = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? tgUserId = freezed,Object? isActive = null,Object? role = null,Object? permissions = null,Object? aiQuotaMonthly = null,Object? aiQuotaUsed = null,Object? aiQuotaResetAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,tgUserId: freezed == tgUserId ? _self.tgUserId : tgUserId // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,aiQuotaMonthly: null == aiQuotaMonthly ? _self.aiQuotaMonthly : aiQuotaMonthly // ignore: cast_nullable_to_non_nullable
as int,aiQuotaUsed: null == aiQuotaUsed ? _self.aiQuotaUsed : aiQuotaUsed // ignore: cast_nullable_to_non_nullable
as int,aiQuotaResetAt: null == aiQuotaResetAt ? _self.aiQuotaResetAt : aiQuotaResetAt // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String username,  String email,  String? displayName,  String? avatarUrl,  int? tgUserId,  bool isActive,  String role, @JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson)  List<String> permissions,  int aiQuotaMonthly,  int aiQuotaUsed, @JsonKey(fromJson: numToDouble)  double aiQuotaResetAt, @JsonKey(fromJson: numToDouble)  double createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.avatarUrl,_that.tgUserId,_that.isActive,_that.role,_that.permissions,_that.aiQuotaMonthly,_that.aiQuotaUsed,_that.aiQuotaResetAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String username,  String email,  String? displayName,  String? avatarUrl,  int? tgUserId,  bool isActive,  String role, @JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson)  List<String> permissions,  int aiQuotaMonthly,  int aiQuotaUsed, @JsonKey(fromJson: numToDouble)  double aiQuotaResetAt, @JsonKey(fromJson: numToDouble)  double createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.avatarUrl,_that.tgUserId,_that.isActive,_that.role,_that.permissions,_that.aiQuotaMonthly,_that.aiQuotaUsed,_that.aiQuotaResetAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String username,  String email,  String? displayName,  String? avatarUrl,  int? tgUserId,  bool isActive,  String role, @JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson)  List<String> permissions,  int aiQuotaMonthly,  int aiQuotaUsed, @JsonKey(fromJson: numToDouble)  double aiQuotaResetAt, @JsonKey(fromJson: numToDouble)  double createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.displayName,_that.avatarUrl,_that.tgUserId,_that.isActive,_that.role,_that.permissions,_that.aiQuotaMonthly,_that.aiQuotaUsed,_that.aiQuotaResetAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _UserProfile extends UserProfile {
  const _UserProfile({required this.id, this.username = '', this.email = '', this.displayName, this.avatarUrl, this.tgUserId, this.isActive = false, this.role = 'user', @JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson) final  List<String> permissions = const [], this.aiQuotaMonthly = 100, this.aiQuotaUsed = 0, @JsonKey(fromJson: numToDouble) this.aiQuotaResetAt = 0.0, @JsonKey(fromJson: numToDouble) this.createdAt = 0.0}): _permissions = permissions,super._();
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  int id;
@override@JsonKey() final  String username;
@override@JsonKey() final  String email;
@override final  String? displayName;
@override final  String? avatarUrl;
@override final  int? tgUserId;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  String role;
// createFactory: false をやめ、@JsonKey のコンバータで特殊パースを実現
 final  List<String> _permissions;
// createFactory: false をやめ、@JsonKey のコンバータで特殊パースを実現
@override@JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson) List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

@override@JsonKey() final  int aiQuotaMonthly;
@override@JsonKey() final  int aiQuotaUsed;
@override@JsonKey(fromJson: numToDouble) final  double aiQuotaResetAt;
@override@JsonKey(fromJson: numToDouble) final  double createdAt;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.tgUserId, tgUserId) || other.tgUserId == tgUserId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.aiQuotaMonthly, aiQuotaMonthly) || other.aiQuotaMonthly == aiQuotaMonthly)&&(identical(other.aiQuotaUsed, aiQuotaUsed) || other.aiQuotaUsed == aiQuotaUsed)&&(identical(other.aiQuotaResetAt, aiQuotaResetAt) || other.aiQuotaResetAt == aiQuotaResetAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,email,displayName,avatarUrl,tgUserId,isActive,role,const DeepCollectionEquality().hash(_permissions),aiQuotaMonthly,aiQuotaUsed,aiQuotaResetAt,createdAt);

@override
String toString() {
  return 'UserProfile(id: $id, username: $username, email: $email, displayName: $displayName, avatarUrl: $avatarUrl, tgUserId: $tgUserId, isActive: $isActive, role: $role, permissions: $permissions, aiQuotaMonthly: $aiQuotaMonthly, aiQuotaUsed: $aiQuotaUsed, aiQuotaResetAt: $aiQuotaResetAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 int id, String username, String email, String? displayName, String? avatarUrl, int? tgUserId, bool isActive, String role,@JsonKey(fromJson: parsePermissions, toJson: _permissionsToJson) List<String> permissions, int aiQuotaMonthly, int aiQuotaUsed,@JsonKey(fromJson: numToDouble) double aiQuotaResetAt,@JsonKey(fromJson: numToDouble) double createdAt
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? email = null,Object? displayName = freezed,Object? avatarUrl = freezed,Object? tgUserId = freezed,Object? isActive = null,Object? role = null,Object? permissions = null,Object? aiQuotaMonthly = null,Object? aiQuotaUsed = null,Object? aiQuotaResetAt = null,Object? createdAt = null,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,tgUserId: freezed == tgUserId ? _self.tgUserId : tgUserId // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,aiQuotaMonthly: null == aiQuotaMonthly ? _self.aiQuotaMonthly : aiQuotaMonthly // ignore: cast_nullable_to_non_nullable
as int,aiQuotaUsed: null == aiQuotaUsed ? _self.aiQuotaUsed : aiQuotaUsed // ignore: cast_nullable_to_non_nullable
as int,aiQuotaResetAt: null == aiQuotaResetAt ? _self.aiQuotaResetAt : aiQuotaResetAt // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
