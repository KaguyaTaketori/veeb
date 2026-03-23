import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/json_converters.dart';
import '../utils/currency.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  const Account._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Account({
    required int id,
    required String name,
    @Default('cash') String type,
    required String currencyCode,
    required int groupId,
    @Default(0) int balanceCache,
    @JsonKey(fromJson: numToDoubleNullable) double? balanceUpdatedAt,
    @Default(true) bool isActive,
    @JsonKey(fromJson: numToDouble) required double createdAt,
    @JsonKey(fromJson: numToDouble) required double updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  double get balanceFloat => intToFloat(balanceCache, currencyCode);
  String get formattedBalance => formatAmount(balanceFloat, currencyCode);

  String get typeLabel => switch (type) {
    'bank' => '银行卡',
    'credit_card' => '信用卡',
    _ => '现金',
  };

  String get typeIcon => switch (type) {
    'bank' => '🏦',
    'credit_card' => '💳',
    _ => '💵',
  };
}
