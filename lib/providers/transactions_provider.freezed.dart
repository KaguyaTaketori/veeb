// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transactions_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionsState implements DiagnosticableTreeMixin {

 List<Transaction> get transactions; bool get loading; String? get error; bool get hasNext; int get page; double get monthExpense; double get monthIncome; int get monthCount; String get keyword; String? get typeFilter;
/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionsStateCopyWith<TransactionsState> get copyWith => _$TransactionsStateCopyWithImpl<TransactionsState>(this as TransactionsState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TransactionsState'))
    ..add(DiagnosticsProperty('transactions', transactions))..add(DiagnosticsProperty('loading', loading))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('hasNext', hasNext))..add(DiagnosticsProperty('page', page))..add(DiagnosticsProperty('monthExpense', monthExpense))..add(DiagnosticsProperty('monthIncome', monthIncome))..add(DiagnosticsProperty('monthCount', monthCount))..add(DiagnosticsProperty('keyword', keyword))..add(DiagnosticsProperty('typeFilter', typeFilter));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionsState&&const DeepCollectionEquality().equals(other.transactions, transactions)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.page, page) || other.page == page)&&(identical(other.monthExpense, monthExpense) || other.monthExpense == monthExpense)&&(identical(other.monthIncome, monthIncome) || other.monthIncome == monthIncome)&&(identical(other.monthCount, monthCount) || other.monthCount == monthCount)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.typeFilter, typeFilter) || other.typeFilter == typeFilter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(transactions),loading,error,hasNext,page,monthExpense,monthIncome,monthCount,keyword,typeFilter);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TransactionsState(transactions: $transactions, loading: $loading, error: $error, hasNext: $hasNext, page: $page, monthExpense: $monthExpense, monthIncome: $monthIncome, monthCount: $monthCount, keyword: $keyword, typeFilter: $typeFilter)';
}


}

/// @nodoc
abstract mixin class $TransactionsStateCopyWith<$Res>  {
  factory $TransactionsStateCopyWith(TransactionsState value, $Res Function(TransactionsState) _then) = _$TransactionsStateCopyWithImpl;
@useResult
$Res call({
 List<Transaction> transactions, bool loading, String? error, bool hasNext, int page, double monthExpense, double monthIncome, int monthCount, String keyword, String? typeFilter
});




}
/// @nodoc
class _$TransactionsStateCopyWithImpl<$Res>
    implements $TransactionsStateCopyWith<$Res> {
  _$TransactionsStateCopyWithImpl(this._self, this._then);

  final TransactionsState _self;
  final $Res Function(TransactionsState) _then;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transactions = null,Object? loading = null,Object? error = freezed,Object? hasNext = null,Object? page = null,Object? monthExpense = null,Object? monthIncome = null,Object? monthCount = null,Object? keyword = null,Object? typeFilter = freezed,}) {
  return _then(_self.copyWith(
transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<Transaction>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,monthExpense: null == monthExpense ? _self.monthExpense : monthExpense // ignore: cast_nullable_to_non_nullable
as double,monthIncome: null == monthIncome ? _self.monthIncome : monthIncome // ignore: cast_nullable_to_non_nullable
as double,monthCount: null == monthCount ? _self.monthCount : monthCount // ignore: cast_nullable_to_non_nullable
as int,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,typeFilter: freezed == typeFilter ? _self.typeFilter : typeFilter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionsState].
extension TransactionsStatePatterns on TransactionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionsState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionsState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Transaction> transactions,  bool loading,  String? error,  bool hasNext,  int page,  double monthExpense,  double monthIncome,  int monthCount,  String keyword,  String? typeFilter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that.transactions,_that.loading,_that.error,_that.hasNext,_that.page,_that.monthExpense,_that.monthIncome,_that.monthCount,_that.keyword,_that.typeFilter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Transaction> transactions,  bool loading,  String? error,  bool hasNext,  int page,  double monthExpense,  double monthIncome,  int monthCount,  String keyword,  String? typeFilter)  $default,) {final _that = this;
switch (_that) {
case _TransactionsState():
return $default(_that.transactions,_that.loading,_that.error,_that.hasNext,_that.page,_that.monthExpense,_that.monthIncome,_that.monthCount,_that.keyword,_that.typeFilter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Transaction> transactions,  bool loading,  String? error,  bool hasNext,  int page,  double monthExpense,  double monthIncome,  int monthCount,  String keyword,  String? typeFilter)?  $default,) {final _that = this;
switch (_that) {
case _TransactionsState() when $default != null:
return $default(_that.transactions,_that.loading,_that.error,_that.hasNext,_that.page,_that.monthExpense,_that.monthIncome,_that.monthCount,_that.keyword,_that.typeFilter);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionsState with DiagnosticableTreeMixin implements TransactionsState {
  const _TransactionsState({final  List<Transaction> transactions = const [], this.loading = false, this.error, this.hasNext = false, this.page = 1, this.monthExpense = 0.0, this.monthIncome = 0.0, this.monthCount = 0, this.keyword = '', this.typeFilter}): _transactions = transactions;
  

 final  List<Transaction> _transactions;
@override@JsonKey() List<Transaction> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}

@override@JsonKey() final  bool loading;
@override final  String? error;
@override@JsonKey() final  bool hasNext;
@override@JsonKey() final  int page;
@override@JsonKey() final  double monthExpense;
@override@JsonKey() final  double monthIncome;
@override@JsonKey() final  int monthCount;
@override@JsonKey() final  String keyword;
@override final  String? typeFilter;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionsStateCopyWith<_TransactionsState> get copyWith => __$TransactionsStateCopyWithImpl<_TransactionsState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TransactionsState'))
    ..add(DiagnosticsProperty('transactions', transactions))..add(DiagnosticsProperty('loading', loading))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('hasNext', hasNext))..add(DiagnosticsProperty('page', page))..add(DiagnosticsProperty('monthExpense', monthExpense))..add(DiagnosticsProperty('monthIncome', monthIncome))..add(DiagnosticsProperty('monthCount', monthCount))..add(DiagnosticsProperty('keyword', keyword))..add(DiagnosticsProperty('typeFilter', typeFilter));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionsState&&const DeepCollectionEquality().equals(other._transactions, _transactions)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.error, error) || other.error == error)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.page, page) || other.page == page)&&(identical(other.monthExpense, monthExpense) || other.monthExpense == monthExpense)&&(identical(other.monthIncome, monthIncome) || other.monthIncome == monthIncome)&&(identical(other.monthCount, monthCount) || other.monthCount == monthCount)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.typeFilter, typeFilter) || other.typeFilter == typeFilter));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transactions),loading,error,hasNext,page,monthExpense,monthIncome,monthCount,keyword,typeFilter);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TransactionsState(transactions: $transactions, loading: $loading, error: $error, hasNext: $hasNext, page: $page, monthExpense: $monthExpense, monthIncome: $monthIncome, monthCount: $monthCount, keyword: $keyword, typeFilter: $typeFilter)';
}


}

/// @nodoc
abstract mixin class _$TransactionsStateCopyWith<$Res> implements $TransactionsStateCopyWith<$Res> {
  factory _$TransactionsStateCopyWith(_TransactionsState value, $Res Function(_TransactionsState) _then) = __$TransactionsStateCopyWithImpl;
@override @useResult
$Res call({
 List<Transaction> transactions, bool loading, String? error, bool hasNext, int page, double monthExpense, double monthIncome, int monthCount, String keyword, String? typeFilter
});




}
/// @nodoc
class __$TransactionsStateCopyWithImpl<$Res>
    implements _$TransactionsStateCopyWith<$Res> {
  __$TransactionsStateCopyWithImpl(this._self, this._then);

  final _TransactionsState _self;
  final $Res Function(_TransactionsState) _then;

/// Create a copy of TransactionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transactions = null,Object? loading = null,Object? error = freezed,Object? hasNext = null,Object? page = null,Object? monthExpense = null,Object? monthIncome = null,Object? monthCount = null,Object? keyword = null,Object? typeFilter = freezed,}) {
  return _then(_TransactionsState(
transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<Transaction>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,monthExpense: null == monthExpense ? _self.monthExpense : monthExpense // ignore: cast_nullable_to_non_nullable
as double,monthIncome: null == monthIncome ? _self.monthIncome : monthIncome // ignore: cast_nullable_to_non_nullable
as double,monthCount: null == monthCount ? _self.monthCount : monthCount // ignore: cast_nullable_to_non_nullable
as int,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,typeFilter: freezed == typeFilter ? _self.typeFilter : typeFilter // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
