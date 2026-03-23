import '../utils/currency.dart';

class Account {
  final int id;
  final String name;
  final String type; // cash / bank / credit_card
  final String currencyCode;
  final int groupId;
  final int balanceCache; // 整数，最小单位
  final double? balanceUpdatedAt;
  final bool isActive;
  final double createdAt;
  final double updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.groupId,
    required this.balanceCache,
    this.balanceUpdatedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  double get balanceFloat => intToFloat(balanceCache, currencyCode);

  String get formattedBalance => formatAmount(balanceFloat, currencyCode);

  String get typeLabel {
    switch (type) {
      case 'bank':
        return '银行卡';
      case 'credit_card':
        return '信用卡';
      default:
        return '现金';
    }
  }

  String get typeIcon {
    switch (type) {
      case 'bank':
        return '🏦';
      case 'credit_card':
        return '💳';
      default:
        return '💵';
    }
  }

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: j['id'] as int,
    name: j['name'] as String,
    type: j['type'] as String? ?? 'cash',
    currencyCode: j['currency_code'] as String? ?? 'JPY',
    groupId: j['group_id'] as int,
    balanceCache: j['balance_cache'] as int? ?? 0,
    balanceUpdatedAt: (j['balance_updated_at'] as num?)?.toDouble(),
    isActive: j['is_active'] as bool? ?? true,
    createdAt: (j['created_at'] as num).toDouble(),
    updatedAt: (j['updated_at'] as num).toDouble(),
  );
}
