// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {

 int get id; String get name; String get type; String get currencyCode; int get groupId; int get balanceCache;@JsonKey(fromJson: numToDoubleNullable) double? get balanceUpdatedAt; bool get isActive;@JsonKey(fromJson: numToDouble) double get createdAt;@JsonKey(fromJson: numToDouble) double get updatedAt;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.balanceCache, balanceCache) || other.balanceCache == balanceCache)&&(identical(other.balanceUpdatedAt, balanceUpdatedAt) || other.balanceUpdatedAt == balanceUpdatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,currencyCode,groupId,balanceCache,balanceUpdatedAt,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'Account(id: $id, name: $name, type: $type, currencyCode: $currencyCode, groupId: $groupId, balanceCache: $balanceCache, balanceUpdatedAt: $balanceUpdatedAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 int id, String name, String type, String currencyCode, int groupId, int balanceCache,@JsonKey(fromJson: numToDoubleNullable) double? balanceUpdatedAt, bool isActive,@JsonKey(fromJson: numToDouble) double createdAt,@JsonKey(fromJson: numToDouble) double updatedAt
});




}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? currencyCode = null,Object? groupId = null,Object? balanceCache = null,Object? balanceUpdatedAt = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int,balanceCache: null == balanceCache ? _self.balanceCache : balanceCache // ignore: cast_nullable_to_non_nullable
as int,balanceUpdatedAt: freezed == balanceUpdatedAt ? _self.balanceUpdatedAt : balanceUpdatedAt // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String type,  String currencyCode,  int groupId,  int balanceCache, @JsonKey(fromJson: numToDoubleNullable)  double? balanceUpdatedAt,  bool isActive, @JsonKey(fromJson: numToDouble)  double createdAt, @JsonKey(fromJson: numToDouble)  double updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.currencyCode,_that.groupId,_that.balanceCache,_that.balanceUpdatedAt,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String type,  String currencyCode,  int groupId,  int balanceCache, @JsonKey(fromJson: numToDoubleNullable)  double? balanceUpdatedAt,  bool isActive, @JsonKey(fromJson: numToDouble)  double createdAt, @JsonKey(fromJson: numToDouble)  double updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.name,_that.type,_that.currencyCode,_that.groupId,_that.balanceCache,_that.balanceUpdatedAt,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String type,  String currencyCode,  int groupId,  int balanceCache, @JsonKey(fromJson: numToDoubleNullable)  double? balanceUpdatedAt,  bool isActive, @JsonKey(fromJson: numToDouble)  double createdAt, @JsonKey(fromJson: numToDouble)  double updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.currencyCode,_that.groupId,_that.balanceCache,_that.balanceUpdatedAt,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Account extends Account {
  const _Account({required this.id, required this.name, this.type = 'cash', required this.currencyCode, required this.groupId, this.balanceCache = 0, @JsonKey(fromJson: numToDoubleNullable) this.balanceUpdatedAt, this.isActive = true, @JsonKey(fromJson: numToDouble) required this.createdAt, @JsonKey(fromJson: numToDouble) required this.updatedAt}): super._();
  factory _Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey() final  String type;
@override final  String currencyCode;
@override final  int groupId;
@override@JsonKey() final  int balanceCache;
@override@JsonKey(fromJson: numToDoubleNullable) final  double? balanceUpdatedAt;
@override@JsonKey() final  bool isActive;
@override@JsonKey(fromJson: numToDouble) final  double createdAt;
@override@JsonKey(fromJson: numToDouble) final  double updatedAt;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.balanceCache, balanceCache) || other.balanceCache == balanceCache)&&(identical(other.balanceUpdatedAt, balanceUpdatedAt) || other.balanceUpdatedAt == balanceUpdatedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,currencyCode,groupId,balanceCache,balanceUpdatedAt,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'Account(id: $id, name: $name, type: $type, currencyCode: $currencyCode, groupId: $groupId, balanceCache: $balanceCache, balanceUpdatedAt: $balanceUpdatedAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String type, String currencyCode, int groupId, int balanceCache,@JsonKey(fromJson: numToDoubleNullable) double? balanceUpdatedAt, bool isActive,@JsonKey(fromJson: numToDouble) double createdAt,@JsonKey(fromJson: numToDouble) double updatedAt
});




}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? currencyCode = null,Object? groupId = null,Object? balanceCache = null,Object? balanceUpdatedAt = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int,balanceCache: null == balanceCache ? _self.balanceCache : balanceCache // ignore: cast_nullable_to_non_nullable
as int,balanceUpdatedAt: freezed == balanceUpdatedAt ? _self.balanceUpdatedAt : balanceUpdatedAt // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
