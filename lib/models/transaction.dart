import '../utils/currency.dart';

class TransactionItem {
  final int? id;
  final String name;
  final String nameRaw;
  final double quantity;
  final double? unitPrice;
  final double amount;
  final String itemType;
  final int sortOrder;

  const TransactionItem({
    this.id,
    required this.name,
    this.nameRaw = '',
    this.quantity = 1.0,
    this.unitPrice,
    required this.amount,
    this.itemType = 'item',
    this.sortOrder = 0,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> j) => TransactionItem(
    id: j['id'] as int?,
    name: j['name'] as String,
    nameRaw: j['name_raw'] as String? ?? '',
    quantity: (j['quantity'] as num?)?.toDouble() ?? 1.0,
    unitPrice: (j['unit_price'] as num?)?.toDouble(),
    amount: (j['amount'] as num).toDouble(),
    itemType: j['item_type'] as String? ?? 'item',
    sortOrder: j['sort_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'name_raw': nameRaw,
    'quantity': quantity,
    if (unitPrice != null) 'unit_price': unitPrice,
    'amount': amount,
    'item_type': itemType,
    'sort_order': sortOrder,
  };
}

class Transaction {
  final int id;
  final String type; // income / expense / transfer
  final double amount;
  final String currencyCode;
  final double baseAmount;
  final double exchangeRate;
  final int accountId;
  final int? toAccountId;
  final int? transferPeerId;
  final int categoryId;
  final int userId;
  final int groupId;
  final bool isPrivate;
  final String? note;
  final String? payee;
  final double transactionDate;
  final String receiptUrl;
  final List<TransactionItem> items;
  final double createdAt;
  final double updatedAt;
  final bool isDeleted;

  // 本地 join 字段（列表页展示用）
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? accountName;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.baseAmount,
    required this.exchangeRate,
    required this.accountId,
    this.toAccountId,
    this.transferPeerId,
    required this.categoryId,
    required this.userId,
    required this.groupId,
    this.isPrivate = false,
    this.note,
    this.payee,
    required this.transactionDate,
    this.receiptUrl = '',
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.accountName,
  });

  bool get hasReceipt => receiptUrl.isNotEmpty;

  String get formattedAmount => formatAmount(amount, currencyCode);

  DateTime get date =>
      DateTime.fromMillisecondsSinceEpoch((transactionDate * 1000).toInt());

  String? get sourceLabel => null;

  String? get displayPayee {
    if (type == 'transfer') return null;
    if (payee != null && payee!.isNotEmpty) return payee;
    return null;
  }

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id: j['id'] as int,
    type: j['type'] as String,
    amount: (j['amount'] as num).toDouble(),
    currencyCode: j['currency_code'] as String? ?? 'JPY',
    baseAmount: (j['base_amount'] as num).toDouble(),
    exchangeRate: (j['exchange_rate'] as num?)?.toDouble() ?? 1.0,
    accountId: j['account_id'] as int,
    toAccountId: j['to_account_id'] as int?,
    transferPeerId: j['transfer_peer_id'] as int?,
    categoryId: j['category_id'] as int,
    userId: j['user_id'] as int,
    groupId: j['group_id'] as int,
    isPrivate: j['is_private'] as bool? ?? false,
    note: j['note'] as String?,
    payee: (j['payee'] ?? j['merchant']) as String?,
    transactionDate: (j['transaction_date'] as num).toDouble(),
    receiptUrl: j['receipt_url'] as String? ?? '',
    items: (j['items'] as List? ?? [])
        .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: (j['created_at'] as num).toDouble(),
    updatedAt: (j['updated_at'] as num).toDouble(),
    isDeleted: j['is_deleted'] as bool? ?? false,
    categoryName: j['category_name'] as String?,
    categoryIcon: j['category_icon'] as String?,
    categoryColor: j['category_color'] as String?,
    accountName: j['account_name'] as String?,
  );

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

// ── 月度汇总 ─────────────────────────────────────────────────────────────────

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

// ── Category ──────────────────────────────────────────────────────────────────

class Category {
  final int id;
  final String name;
  final String icon;
  final String color;
  final String type; // income / expense / both
  final bool isSystem;
  final int? groupId;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isSystem,
    this.groupId,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as int,
    name: j['name'] as String,
    icon: j['icon'] as String? ?? '📦',
    color: j['color'] as String? ?? '#95A5A6',
    type: j['type'] as String? ?? 'expense',
    isSystem: j['is_system'] as bool? ?? false,
    groupId: j['group_id'] as int?,
    sortOrder: j['sort_order'] as int? ?? 0,
  );
}
