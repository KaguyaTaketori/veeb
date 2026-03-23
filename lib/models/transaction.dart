import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/json_converters.dart';
import '../utils/currency.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

// ── トップレベル関数 ──────────────────────────────────────────────────────────

// payee フィールド: JSON に 'payee' がなければ 'merchant' にフォールバック
Object? _readPayeeOrMerchant(Map<dynamic, dynamic> map, String key) =>
    map['payee'] ?? map['merchant'];

// quantity: JSON が null のとき 1.0 を返す
double _numToDoubleOrOne(dynamic v) => v == null ? 1.0 : (v as num).toDouble();

// ── TransactionItem ───────────────────────────────────────────────────────────

@freezed
abstract class TransactionItem with _$TransactionItem {
  // createFactory: false を削除 — includeIfNull: false は toJson 側だけなので残す
  @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
  const factory TransactionItem({
    int? id,
    required String name,
    @Default('') String nameRaw,
    @Default(1.0) @JsonKey(fromJson: _numToDoubleOrOne) double quantity,
    @JsonKey(fromJson: numToDoubleNullable) double? unitPrice,
    @JsonKey(fromJson: numToDouble) required double amount,
    @Default('item') String itemType,
    @Default(0) int sortOrder,
  }) = _TransactionItem;

  factory TransactionItem.fromJson(Map<String, dynamic> j) =>
      _$TransactionItemFromJson(j);
}

// ── Category ──────────────────────────────────────────────────────────────────

@freezed
abstract class Category with _$Category {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Category({
    required int id,
    required String name,
    @Default('📦') String icon,
    @Default('#95A5A6') String color,
    @Default('expense') String type,
    @Default(false) bool isSystem,
    int? groupId,
    @Default(0) int sortOrder,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

// ── Transaction ───────────────────────────────────────────────────────────────

@freezed
abstract class Transaction with _$Transaction {
  const Transaction._();

  // createFactory: false を削除
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Transaction({
    required int id,
    required String type,
    @JsonKey(fromJson: numToDouble) required double amount,
    required String currencyCode,
    @JsonKey(fromJson: numToDouble) required double baseAmount,
    @Default(1.0) @JsonKey(fromJson: numToDouble) double exchangeRate,
    required int accountId,
    int? toAccountId,
    int? transferPeerId,
    required int categoryId,
    required int userId,
    required int groupId,
    @Default(false) bool isPrivate,
    String? note,
    // readValue で 'payee' → 'merchant' フォールバックを実現
    @JsonKey(readValue: _readPayeeOrMerchant) String? payee,
    @JsonKey(fromJson: numToDouble) required double transactionDate,
    @Default('') String receiptUrl,
    @Default([]) List<TransactionItem> items,
    @JsonKey(fromJson: numToDouble) required double createdAt,
    @JsonKey(fromJson: numToDouble) required double updatedAt,
    @Default(false) bool isDeleted,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? accountName,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> j) =>
      _$TransactionFromJson(j);

  bool get hasReceipt => receiptUrl.isNotEmpty;
  String get formattedAmount => formatAmount(amount, currencyCode);
  DateTime get date =>
      DateTime.fromMillisecondsSinceEpoch((transactionDate * 1000).toInt());

  String? get displayPayee {
    if (type == 'transfer') return null;
    if (payee != null && payee!.isNotEmpty) return payee;
    return null;
  }

  Map<String, dynamic> toCreateJson() => {
    'type': type,
    'amount': amount,
    'currency_code': currencyCode,
    'exchange_rate': exchangeRate,
    'account_id': accountId,
    if (toAccountId != null) 'to_account_id': toAccountId,
    'category_id': categoryId,
    'group_id': groupId,
    'is_private': isPrivate,
    if (note != null) 'note': note,
    if (payee != null && payee!.isNotEmpty) 'payee': payee,
    'transaction_date': transactionDate,
    if (receiptUrl.isNotEmpty) 'receipt_url': receiptUrl,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class CategoryStat {
  final int categoryId;
  final String name;
  final String icon;
  final String color;
  final double total;
  final int count;
  final double percent;

  const CategoryStat({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.count,
    required this.percent,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> j) => CategoryStat(
    categoryId: j['category_id'] as int,
    name: j['name'] as String,
    icon: j['icon'] as String? ?? '📦',
    color: j['color'] as String? ?? '#95A5A6',
    total: (j['total'] as num).toDouble(),
    count: j['count'] as int,
    percent: (j['percent'] as num?)?.toDouble() ?? 0.0,
  );
}

class MonthlyStat {
  final int year;
  final int month;
  final double totalExpense;
  final double totalIncome;
  final double net;
  final int count;
  final List<CategoryStat> byCategory;
  final List<Map<String, dynamic>> byCurrency;

  const MonthlyStat({
    required this.year,
    required this.month,
    required this.totalExpense,
    required this.totalIncome,
    required this.net,
    required this.count,
    required this.byCategory,
    required this.byCurrency,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> j) => MonthlyStat(
    year: j['year'] as int,
    month: j['month'] as int,
    totalExpense: (j['total_expense'] as num).toDouble(),
    totalIncome: (j['total_income'] as num).toDouble(),
    net: (j['net'] as num).toDouble(),
    count: j['count'] as int,
    byCategory: (j['by_category'] as List? ?? [])
        .map((e) => CategoryStat.fromJson(e as Map<String, dynamic>))
        .toList(),
    byCurrency: (j['by_currency'] as List? ?? []).cast<Map<String, dynamic>>(),
  );
}
