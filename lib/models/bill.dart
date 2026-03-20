// lib/models/bill.dart

class BillItem {
  final int? id;
  final String name;
  final String nameRaw;
  final double quantity;
  final double? unitPrice;
  final double amount;
  final String itemType;
  final int sortOrder;

  BillItem({
    this.id,
    required this.name,
    this.nameRaw = '',
    this.quantity = 1.0,
    this.unitPrice,
    required this.amount,
    this.itemType = 'item',
    this.sortOrder = 0,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        id: json['id'] as int?,
        name: json['name'] as String,
        nameRaw: json['name_raw'] as String? ?? '',
        quantity: (json['quantity'] ?? 1.0).toDouble(),
        unitPrice: (json['unit_price'] as num?)?.toDouble(),
        amount: (json['amount'] ?? 0).toDouble(),
        itemType: json['item_type'] as String? ?? 'item',
        sortOrder: json['sort_order'] as int? ?? 0,
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

class Bill {
  final int id;
  final double amount;
  final String currency;
  final String? category;
  final String? description;
  final String? merchant;
  final String? billDate;
  final String receiptUrl;   // ← 新增
  final List<BillItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;

  Bill({
    required this.id,
    required this.amount,
    required this.currency,
    this.category,
    this.description,
    this.merchant,
    this.billDate,
    this.receiptUrl = '',
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasReceipt => receiptUrl.isNotEmpty;

  String get displayMerchant {
    if (merchant == null || merchant!.isEmpty || merchant == '未知商家') {
      return category ?? '未分類';
    }
    return merchant!;
  }

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: (json['id'] as int?) ?? 0,
        amount: (json['amount'] ?? 0).toDouble(),
        currency: json['currency'] as String? ?? 'JPY',
        category: json['category'] as String?,
        description: json['description'] as String?,
        merchant: json['merchant'] as String?,
        billDate: json['bill_date'] as String?,
        receiptUrl: json['receipt_url'] as String? ?? '',
        items: (json['items'] as List? ?? [])
            .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: _parseTimestamp(json['created_at']),
        updatedAt: _parseTimestamp(json['updated_at']),
        source: json['source'] as String? ?? 'app',
      );

  String? get sourceLabel {
    switch (source) {
      case 'bot': return 'Bot';
      case 'web': return 'Web';
      default:    return null;
    }
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final ms = (raw as num).toDouble();
    final epochMs = ms < 1e10 ? (ms * 1000).toInt() : ms.toInt();
    return DateTime.fromMillisecondsSinceEpoch(epochMs);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (merchant != null) 'merchant': merchant,
        if (billDate != null) 'bill_date': billDate,
        'receipt_url': receiptUrl,
        'items': items.map((e) => e.toJson()).toList(),
        'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
        'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
      };

  /// 用于编辑时的浅拷贝
  Bill copyWith({
    double? amount,
    String? currency,
    String? category,
    String? description,
    String? merchant,
    String? billDate,
    String? receiptUrl,
    List<BillItem>? items,
  }) =>
      Bill(
        id: id,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        category: category ?? this.category,
        description: description ?? this.description,
        merchant: merchant ?? this.merchant,
        billDate: billDate ?? this.billDate,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        items: items ?? this.items,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class MonthlySummary {
  final int year;
  final int month;
  final double total;
  final int count;
  final List<CategorySummary> byCategory;
  final List<CurrencySummary> byCurrency;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.total,
    required this.count,
    required this.byCategory,
    required this.byCurrency,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        year: json['year'] as int,
        month: json['month'] as int,
        total: (json['total'] ?? 0).toDouble(),
        count: json['count'] as int? ?? 0,
        byCategory: (json['by_category'] as List? ?? [])
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        byCurrency: (json['by_currency'] as List? ?? [])
            .map((e) => CurrencySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CategorySummary {
  final String category;
  final double total;
  final int count;

  CategorySummary({
    required this.category,
    required this.total,
    required this.count,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        category: json['category'] as String,
        total: (json['total'] ?? 0).toDouble(),
        count: json['count'] as int? ?? 0,
      );
}

class CurrencySummary {
  final String currency;
  final double total;

  CurrencySummary({required this.currency, required this.total});

  factory CurrencySummary.fromJson(Map<String, dynamic> json) =>
      CurrencySummary(
        currency: json['currency'] as String,
        total: (json['total'] ?? 0).toDouble(),
      );
}