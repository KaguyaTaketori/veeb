// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionItem {

 int? get id; String get name; String get nameRaw;@JsonKey(fromJson: _numToDoubleOrOne) double get quantity;@JsonKey(fromJson: numToDoubleNullable) double? get unitPrice;@JsonKey(fromJson: numToDouble) double get amount; String get itemType; int get sortOrder;
/// Create a copy of TransactionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionItemCopyWith<TransactionItem> get copyWith => _$TransactionItemCopyWithImpl<TransactionItem>(this as TransactionItem, _$identity);

  /// Serializes this TransactionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameRaw, nameRaw) || other.nameRaw == nameRaw)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.itemType, itemType) || other.itemType == itemType)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameRaw,quantity,unitPrice,amount,itemType,sortOrder);

@override
String toString() {
  return 'TransactionItem(id: $id, name: $name, nameRaw: $nameRaw, quantity: $quantity, unitPrice: $unitPrice, amount: $amount, itemType: $itemType, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $TransactionItemCopyWith<$Res>  {
  factory $TransactionItemCopyWith(TransactionItem value, $Res Function(TransactionItem) _then) = _$TransactionItemCopyWithImpl;
@useResult
$Res call({
 int? id, String name, String nameRaw,@JsonKey(fromJson: _numToDoubleOrOne) double quantity,@JsonKey(fromJson: numToDoubleNullable) double? unitPrice,@JsonKey(fromJson: numToDouble) double amount, String itemType, int sortOrder
});




}
/// @nodoc
class _$TransactionItemCopyWithImpl<$Res>
    implements $TransactionItemCopyWith<$Res> {
  _$TransactionItemCopyWithImpl(this._self, this._then);

  final TransactionItem _self;
  final $Res Function(TransactionItem) _then;

/// Create a copy of TransactionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? nameRaw = null,Object? quantity = null,Object? unitPrice = freezed,Object? amount = null,Object? itemType = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameRaw: null == nameRaw ? _self.nameRaw : nameRaw // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,itemType: null == itemType ? _self.itemType : itemType // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionItem].
extension TransactionItemPatterns on TransactionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionItem value)  $default,){
final _that = this;
switch (_that) {
case _TransactionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionItem value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name,  String nameRaw, @JsonKey(fromJson: _numToDoubleOrOne)  double quantity, @JsonKey(fromJson: numToDoubleNullable)  double? unitPrice, @JsonKey(fromJson: numToDouble)  double amount,  String itemType,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionItem() when $default != null:
return $default(_that.id,_that.name,_that.nameRaw,_that.quantity,_that.unitPrice,_that.amount,_that.itemType,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name,  String nameRaw, @JsonKey(fromJson: _numToDoubleOrOne)  double quantity, @JsonKey(fromJson: numToDoubleNullable)  double? unitPrice, @JsonKey(fromJson: numToDouble)  double amount,  String itemType,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _TransactionItem():
return $default(_that.id,_that.name,_that.nameRaw,_that.quantity,_that.unitPrice,_that.amount,_that.itemType,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name,  String nameRaw, @JsonKey(fromJson: _numToDoubleOrOne)  double quantity, @JsonKey(fromJson: numToDoubleNullable)  double? unitPrice, @JsonKey(fromJson: numToDouble)  double amount,  String itemType,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _TransactionItem() when $default != null:
return $default(_that.id,_that.name,_that.nameRaw,_that.quantity,_that.unitPrice,_that.amount,_that.itemType,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class _TransactionItem implements TransactionItem {
  const _TransactionItem({this.id, required this.name, this.nameRaw = '', @JsonKey(fromJson: _numToDoubleOrOne) this.quantity = 1.0, @JsonKey(fromJson: numToDoubleNullable) this.unitPrice, @JsonKey(fromJson: numToDouble) required this.amount, this.itemType = 'item', this.sortOrder = 0});
  factory _TransactionItem.fromJson(Map<String, dynamic> json) => _$TransactionItemFromJson(json);

@override final  int? id;
@override final  String name;
@override@JsonKey() final  String nameRaw;
@override@JsonKey(fromJson: _numToDoubleOrOne) final  double quantity;
@override@JsonKey(fromJson: numToDoubleNullable) final  double? unitPrice;
@override@JsonKey(fromJson: numToDouble) final  double amount;
@override@JsonKey() final  String itemType;
@override@JsonKey() final  int sortOrder;

/// Create a copy of TransactionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionItemCopyWith<_TransactionItem> get copyWith => __$TransactionItemCopyWithImpl<_TransactionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameRaw, nameRaw) || other.nameRaw == nameRaw)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.itemType, itemType) || other.itemType == itemType)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameRaw,quantity,unitPrice,amount,itemType,sortOrder);

@override
String toString() {
  return 'TransactionItem(id: $id, name: $name, nameRaw: $nameRaw, quantity: $quantity, unitPrice: $unitPrice, amount: $amount, itemType: $itemType, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$TransactionItemCopyWith<$Res> implements $TransactionItemCopyWith<$Res> {
  factory _$TransactionItemCopyWith(_TransactionItem value, $Res Function(_TransactionItem) _then) = __$TransactionItemCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name, String nameRaw,@JsonKey(fromJson: _numToDoubleOrOne) double quantity,@JsonKey(fromJson: numToDoubleNullable) double? unitPrice,@JsonKey(fromJson: numToDouble) double amount, String itemType, int sortOrder
});




}
/// @nodoc
class __$TransactionItemCopyWithImpl<$Res>
    implements _$TransactionItemCopyWith<$Res> {
  __$TransactionItemCopyWithImpl(this._self, this._then);

  final _TransactionItem _self;
  final $Res Function(_TransactionItem) _then;

/// Create a copy of TransactionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? nameRaw = null,Object? quantity = null,Object? unitPrice = freezed,Object? amount = null,Object? itemType = null,Object? sortOrder = null,}) {
  return _then(_TransactionItem(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameRaw: null == nameRaw ? _self.nameRaw : nameRaw // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,itemType: null == itemType ? _self.itemType : itemType // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Category {

 int get id; String get name; String get icon; String get color; String get type; bool get isSystem; int? get groupId; int get sortOrder;
/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryCopyWith<Category> get copyWith => _$CategoryCopyWithImpl<Category>(this as Category, _$identity);

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Category&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,type,isSystem,groupId,sortOrder);

@override
String toString() {
  return 'Category(id: $id, name: $name, icon: $icon, color: $color, type: $type, isSystem: $isSystem, groupId: $groupId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CategoryCopyWith<$Res>  {
  factory $CategoryCopyWith(Category value, $Res Function(Category) _then) = _$CategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String icon, String color, String type, bool isSystem, int? groupId, int sortOrder
});




}
/// @nodoc
class _$CategoryCopyWithImpl<$Res>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._self, this._then);

  final Category _self;
  final $Res Function(Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? type = null,Object? isSystem = null,Object? groupId = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Category].
extension CategoryPatterns on Category {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Category value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Category value)  $default,){
final _that = this;
switch (_that) {
case _Category():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Category value)?  $default,){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String icon,  String color,  String type,  bool isSystem,  int? groupId,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.color,_that.type,_that.isSystem,_that.groupId,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String icon,  String color,  String type,  bool isSystem,  int? groupId,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Category():
return $default(_that.id,_that.name,_that.icon,_that.color,_that.type,_that.isSystem,_that.groupId,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String icon,  String color,  String type,  bool isSystem,  int? groupId,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.color,_that.type,_that.isSystem,_that.groupId,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Category implements Category {
  const _Category({required this.id, required this.name, this.icon = '📦', this.color = '#95A5A6', this.type = 'expense', this.isSystem = false, this.groupId, this.sortOrder = 0});
  factory _Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey() final  String type;
@override@JsonKey() final  bool isSystem;
@override final  int? groupId;
@override@JsonKey() final  int sortOrder;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryCopyWith<_Category> get copyWith => __$CategoryCopyWithImpl<_Category>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Category&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.type, type) || other.type == type)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,type,isSystem,groupId,sortOrder);

@override
String toString() {
  return 'Category(id: $id, name: $name, icon: $icon, color: $color, type: $type, isSystem: $isSystem, groupId: $groupId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CategoryCopyWith<$Res> implements $CategoryCopyWith<$Res> {
  factory _$CategoryCopyWith(_Category value, $Res Function(_Category) _then) = __$CategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String icon, String color, String type, bool isSystem, int? groupId, int sortOrder
});




}
/// @nodoc
class __$CategoryCopyWithImpl<$Res>
    implements _$CategoryCopyWith<$Res> {
  __$CategoryCopyWithImpl(this._self, this._then);

  final _Category _self;
  final $Res Function(_Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? type = null,Object? isSystem = null,Object? groupId = freezed,Object? sortOrder = null,}) {
  return _then(_Category(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Transaction {

 int get id; String get type;@JsonKey(fromJson: numToDouble) double get amount; String get currencyCode;@JsonKey(fromJson: numToDouble) double get baseAmount;@JsonKey(fromJson: numToDouble) double get exchangeRate; int get accountId; int? get toAccountId; int? get transferPeerId; int get categoryId; int get userId; int get groupId; bool get isPrivate; String? get note;// readValue で 'payee' → 'merchant' フォールバックを実現
@JsonKey(readValue: _readPayeeOrMerchant) String? get payee;@JsonKey(fromJson: numToDouble) double get transactionDate; String get receiptUrl; List<TransactionItem> get items;@JsonKey(fromJson: numToDouble) double get createdAt;@JsonKey(fromJson: numToDouble) double get updatedAt; bool get isDeleted; String? get categoryName; String? get categoryIcon; String? get categoryColor; String? get accountName;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.baseAmount, baseAmount) || other.baseAmount == baseAmount)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.transferPeerId, transferPeerId) || other.transferPeerId == transferPeerId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.note, note) || other.note == note)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.accountName, accountName) || other.accountName == accountName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,amount,currencyCode,baseAmount,exchangeRate,accountId,toAccountId,transferPeerId,categoryId,userId,groupId,isPrivate,note,payee,transactionDate,receiptUrl,const DeepCollectionEquality().hash(items),createdAt,updatedAt,isDeleted,categoryName,categoryIcon,categoryColor,accountName]);

@override
String toString() {
  return 'Transaction(id: $id, type: $type, amount: $amount, currencyCode: $currencyCode, baseAmount: $baseAmount, exchangeRate: $exchangeRate, accountId: $accountId, toAccountId: $toAccountId, transferPeerId: $transferPeerId, categoryId: $categoryId, userId: $userId, groupId: $groupId, isPrivate: $isPrivate, note: $note, payee: $payee, transactionDate: $transactionDate, receiptUrl: $receiptUrl, items: $items, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, categoryName: $categoryName, categoryIcon: $categoryIcon, categoryColor: $categoryColor, accountName: $accountName)';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 int id, String type,@JsonKey(fromJson: numToDouble) double amount, String currencyCode,@JsonKey(fromJson: numToDouble) double baseAmount,@JsonKey(fromJson: numToDouble) double exchangeRate, int accountId, int? toAccountId, int? transferPeerId, int categoryId, int userId, int groupId, bool isPrivate, String? note,@JsonKey(readValue: _readPayeeOrMerchant) String? payee,@JsonKey(fromJson: numToDouble) double transactionDate, String receiptUrl, List<TransactionItem> items,@JsonKey(fromJson: numToDouble) double createdAt,@JsonKey(fromJson: numToDouble) double updatedAt, bool isDeleted, String? categoryName, String? categoryIcon, String? categoryColor, String? accountName
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? currencyCode = null,Object? baseAmount = null,Object? exchangeRate = null,Object? accountId = null,Object? toAccountId = freezed,Object? transferPeerId = freezed,Object? categoryId = null,Object? userId = null,Object? groupId = null,Object? isPrivate = null,Object? note = freezed,Object? payee = freezed,Object? transactionDate = null,Object? receiptUrl = null,Object? items = null,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,Object? categoryName = freezed,Object? categoryIcon = freezed,Object? categoryColor = freezed,Object? accountName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,baseAmount: null == baseAmount ? _self.baseAmount : baseAmount // ignore: cast_nullable_to_non_nullable
as double,exchangeRate: null == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,transferPeerId: freezed == transferPeerId ? _self.transferPeerId : transferPeerId // ignore: cast_nullable_to_non_nullable
as int?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as double,receiptUrl: null == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TransactionItem>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as double,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryColor: freezed == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(fromJson: numToDouble)  double amount,  String currencyCode, @JsonKey(fromJson: numToDouble)  double baseAmount, @JsonKey(fromJson: numToDouble)  double exchangeRate,  int accountId,  int? toAccountId,  int? transferPeerId,  int categoryId,  int userId,  int groupId,  bool isPrivate,  String? note, @JsonKey(readValue: _readPayeeOrMerchant)  String? payee, @JsonKey(fromJson: numToDouble)  double transactionDate,  String receiptUrl,  List<TransactionItem> items, @JsonKey(fromJson: numToDouble)  double createdAt, @JsonKey(fromJson: numToDouble)  double updatedAt,  bool isDeleted,  String? categoryName,  String? categoryIcon,  String? categoryColor,  String? accountName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.currencyCode,_that.baseAmount,_that.exchangeRate,_that.accountId,_that.toAccountId,_that.transferPeerId,_that.categoryId,_that.userId,_that.groupId,_that.isPrivate,_that.note,_that.payee,_that.transactionDate,_that.receiptUrl,_that.items,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.accountName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(fromJson: numToDouble)  double amount,  String currencyCode, @JsonKey(fromJson: numToDouble)  double baseAmount, @JsonKey(fromJson: numToDouble)  double exchangeRate,  int accountId,  int? toAccountId,  int? transferPeerId,  int categoryId,  int userId,  int groupId,  bool isPrivate,  String? note, @JsonKey(readValue: _readPayeeOrMerchant)  String? payee, @JsonKey(fromJson: numToDouble)  double transactionDate,  String receiptUrl,  List<TransactionItem> items, @JsonKey(fromJson: numToDouble)  double createdAt, @JsonKey(fromJson: numToDouble)  double updatedAt,  bool isDeleted,  String? categoryName,  String? categoryIcon,  String? categoryColor,  String? accountName)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.type,_that.amount,_that.currencyCode,_that.baseAmount,_that.exchangeRate,_that.accountId,_that.toAccountId,_that.transferPeerId,_that.categoryId,_that.userId,_that.groupId,_that.isPrivate,_that.note,_that.payee,_that.transactionDate,_that.receiptUrl,_that.items,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.accountName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type, @JsonKey(fromJson: numToDouble)  double amount,  String currencyCode, @JsonKey(fromJson: numToDouble)  double baseAmount, @JsonKey(fromJson: numToDouble)  double exchangeRate,  int accountId,  int? toAccountId,  int? transferPeerId,  int categoryId,  int userId,  int groupId,  bool isPrivate,  String? note, @JsonKey(readValue: _readPayeeOrMerchant)  String? payee, @JsonKey(fromJson: numToDouble)  double transactionDate,  String receiptUrl,  List<TransactionItem> items, @JsonKey(fromJson: numToDouble)  double createdAt, @JsonKey(fromJson: numToDouble)  double updatedAt,  bool isDeleted,  String? categoryName,  String? categoryIcon,  String? categoryColor,  String? accountName)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.currencyCode,_that.baseAmount,_that.exchangeRate,_that.accountId,_that.toAccountId,_that.transferPeerId,_that.categoryId,_that.userId,_that.groupId,_that.isPrivate,_that.note,_that.payee,_that.transactionDate,_that.receiptUrl,_that.items,_that.createdAt,_that.updatedAt,_that.isDeleted,_that.categoryName,_that.categoryIcon,_that.categoryColor,_that.accountName);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Transaction extends Transaction {
  const _Transaction({required this.id, required this.type, @JsonKey(fromJson: numToDouble) required this.amount, required this.currencyCode, @JsonKey(fromJson: numToDouble) required this.baseAmount, @JsonKey(fromJson: numToDouble) this.exchangeRate = 1.0, required this.accountId, this.toAccountId, this.transferPeerId, required this.categoryId, required this.userId, required this.groupId, this.isPrivate = false, this.note, @JsonKey(readValue: _readPayeeOrMerchant) this.payee, @JsonKey(fromJson: numToDouble) required this.transactionDate, this.receiptUrl = '', final  List<TransactionItem> items = const [], @JsonKey(fromJson: numToDouble) required this.createdAt, @JsonKey(fromJson: numToDouble) required this.updatedAt, this.isDeleted = false, this.categoryName, this.categoryIcon, this.categoryColor, this.accountName}): _items = items,super._();
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  int id;
@override final  String type;
@override@JsonKey(fromJson: numToDouble) final  double amount;
@override final  String currencyCode;
@override@JsonKey(fromJson: numToDouble) final  double baseAmount;
@override@JsonKey(fromJson: numToDouble) final  double exchangeRate;
@override final  int accountId;
@override final  int? toAccountId;
@override final  int? transferPeerId;
@override final  int categoryId;
@override final  int userId;
@override final  int groupId;
@override@JsonKey() final  bool isPrivate;
@override final  String? note;
// readValue で 'payee' → 'merchant' フォールバックを実現
@override@JsonKey(readValue: _readPayeeOrMerchant) final  String? payee;
@override@JsonKey(fromJson: numToDouble) final  double transactionDate;
@override@JsonKey() final  String receiptUrl;
 final  List<TransactionItem> _items;
@override@JsonKey() List<TransactionItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(fromJson: numToDouble) final  double createdAt;
@override@JsonKey(fromJson: numToDouble) final  double updatedAt;
@override@JsonKey() final  bool isDeleted;
@override final  String? categoryName;
@override final  String? categoryIcon;
@override final  String? categoryColor;
@override final  String? accountName;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.baseAmount, baseAmount) || other.baseAmount == baseAmount)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.transferPeerId, transferPeerId) || other.transferPeerId == transferPeerId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.note, note) || other.note == note)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.accountName, accountName) || other.accountName == accountName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,type,amount,currencyCode,baseAmount,exchangeRate,accountId,toAccountId,transferPeerId,categoryId,userId,groupId,isPrivate,note,payee,transactionDate,receiptUrl,const DeepCollectionEquality().hash(_items),createdAt,updatedAt,isDeleted,categoryName,categoryIcon,categoryColor,accountName]);

@override
String toString() {
  return 'Transaction(id: $id, type: $type, amount: $amount, currencyCode: $currencyCode, baseAmount: $baseAmount, exchangeRate: $exchangeRate, accountId: $accountId, toAccountId: $toAccountId, transferPeerId: $transferPeerId, categoryId: $categoryId, userId: $userId, groupId: $groupId, isPrivate: $isPrivate, note: $note, payee: $payee, transactionDate: $transactionDate, receiptUrl: $receiptUrl, items: $items, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted, categoryName: $categoryName, categoryIcon: $categoryIcon, categoryColor: $categoryColor, accountName: $accountName)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, String type,@JsonKey(fromJson: numToDouble) double amount, String currencyCode,@JsonKey(fromJson: numToDouble) double baseAmount,@JsonKey(fromJson: numToDouble) double exchangeRate, int accountId, int? toAccountId, int? transferPeerId, int categoryId, int userId, int groupId, bool isPrivate, String? note,@JsonKey(readValue: _readPayeeOrMerchant) String? payee,@JsonKey(fromJson: numToDouble) double transactionDate, String receiptUrl, List<TransactionItem> items,@JsonKey(fromJson: numToDouble) double createdAt,@JsonKey(fromJson: numToDouble) double updatedAt, bool isDeleted, String? categoryName, String? categoryIcon, String? categoryColor, String? accountName
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? currencyCode = null,Object? baseAmount = null,Object? exchangeRate = null,Object? accountId = null,Object? toAccountId = freezed,Object? transferPeerId = freezed,Object? categoryId = null,Object? userId = null,Object? groupId = null,Object? isPrivate = null,Object? note = freezed,Object? payee = freezed,Object? transactionDate = null,Object? receiptUrl = null,Object? items = null,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,Object? categoryName = freezed,Object? categoryIcon = freezed,Object? categoryColor = freezed,Object? accountName = freezed,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,baseAmount: null == baseAmount ? _self.baseAmount : baseAmount // ignore: cast_nullable_to_non_nullable
as double,exchangeRate: null == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as double,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as int?,transferPeerId: freezed == transferPeerId ? _self.transferPeerId : transferPeerId // ignore: cast_nullable_to_non_nullable
as int?,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as int,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,payee: freezed == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as double,receiptUrl: null == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TransactionItem>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as double,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryColor: freezed == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String?,accountName: freezed == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
