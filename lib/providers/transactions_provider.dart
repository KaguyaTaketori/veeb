// lib/providers/transactions_provider.dart
// Fix 1: _driftRowToTransaction 接受 catMap 参数，在 Guest 模式下填充 categoryName/Icon/Color
// Fix 2: _buildAmountHeader 的 hintStyle 设为 48px，与输入文字大小一致

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transactions_api.dart';
import '../database/app_database.dart' as db;
import '../models/transaction.dart' as models;
import 'auth_provider.dart';
import 'group_provider.dart';
import 'database_provider.dart';

// ── State ────────────────────────────────────────────────────────────────────

class TransactionsState {
  final List<models.Transaction> transactions;
  final bool loading;
  final String? error;
  final bool hasNext;
  final int page;
  final double monthExpense;
  final double monthIncome;
  final int monthCount;
  final String keyword;
  final String? typeFilter;

  const TransactionsState({
    this.transactions = const [],
    this.loading = false,
    this.error,
    this.hasNext = false,
    this.page = 1,
    this.monthExpense = 0,
    this.monthIncome = 0,
    this.monthCount = 0,
    this.keyword = '',
    this.typeFilter,
  });

  TransactionsState copyWith({
    List<models.Transaction>? transactions,
    bool? loading,
    String? error,
    bool? hasNext,
    int? page,
    double? monthExpense,
    double? monthIncome,
    int? monthCount,
    String? keyword,
    String? typeFilter,
    bool clearError = false,
  }) => TransactionsState(
    transactions: transactions ?? this.transactions,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    hasNext: hasNext ?? this.hasNext,
    page: page ?? this.page,
    monthExpense: monthExpense ?? this.monthExpense,
    monthIncome: monthIncome ?? this.monthIncome,
    monthCount: monthCount ?? this.monthCount,
    keyword: keyword ?? this.keyword,
    typeFilter: typeFilter ?? this.typeFilter,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TransactionsNotifier extends Notifier<TransactionsState> {
  int _seq = 0;

  @override
  TransactionsState build() => const TransactionsState();

  TransactionsApi get _api => ref.read(transactionsApiProvider);
  db.AppDatabase get _db => ref.read(appDatabaseProvider);

  bool get _isLoggedIn =>
      ref.read(authProvider).status == AuthStatus.authenticated;

  // ── 加载 ──────────────────────────────────────────────────────────────────

  Future<void> load(
    DateTime month, {
    bool refresh = false,
    String? keyword,
    String? typeFilter,
    int? accountId,
  }) async {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;

    final page = refresh ? 1 : state.page;
    final kw = keyword ?? state.keyword;
    final type = typeFilter ?? state.typeFilter;
    final mySeq = ++_seq;

    state = state.copyWith(
      loading: true,
      clearError: true,
      page: page,
      keyword: kw,
      typeFilter: type,
      transactions: refresh ? [] : state.transactions,
    );

    try {
      if (_isLoggedIn) {
        await _loadFromApi(
          month,
          groupId: groupId,
          page: page,
          keyword: kw,
          typeFilter: type,
          accountId: accountId,
          mySeq: mySeq,
        );
      } else {
        await _loadFromLocal(
          month,
          groupId: groupId,
          keyword: kw,
          typeFilter: type,
          mySeq: mySeq,
        );
      }
    } catch (e) {
      if (mySeq != _seq) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── 从 API 加载（已登录）─────────────────────────────────────────────────

  Future<void> _loadFromApi(
    DateTime month, {
    required int groupId,
    required int page,
    required String keyword,
    required String? typeFilter,
    required int? accountId,
    required int mySeq,
  }) async {
    final data = await _api.listTransactions(
      groupId: groupId,
      page: page,
      year: month.year,
      month: month.month,
      keyword: keyword.isEmpty ? null : keyword,
      type: typeFilter,
      accountId: accountId,
    );

    if (mySeq != _seq) return;

    final fetched = (data['transactions'] as List)
        .map((e) => models.Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final merged = state.transactions.isEmpty || page == 1
        ? fetched
        : [...state.transactions, ...fetched];

    _updateStateFromList(merged, data['has_next'] as bool? ?? false);
  }

  // ── 从本地 DB 加载（Guest 模式）──────────────────────────────────────────

  Future<void> _loadFromLocal(
    DateTime month, {
    required int groupId,
    required String keyword,
    required String? typeFilter,
    required int mySeq,
  }) async {
    final rawList = await _db.transactionDao
        .watchByMonth(groupId, month.year, month.month)
        .first;

    if (mySeq != _seq) return;

    // ✅ Fix: 获取分类映射，补充 categoryName / categoryIcon / categoryColor
    // 原版 _driftRowToTransaction 没有 join，导致 Guest 模式下列表显示"请选择"
    final cats = await _db.categoryDao.getAvailable(groupId);
    final catMap = {for (final c in cats) c.id: c};

    var txns = rawList
        .map((row) => _driftRowToTransaction(row, catMap: catMap))
        .toList();

    if (keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      txns = txns
          .where(
            (t) =>
                (t.note?.toLowerCase().contains(kw) ?? false) ||
                (t.categoryName?.toLowerCase().contains(kw) ?? false),
          )
          .toList();
    }

    if (typeFilter != null) {
      txns = txns.where((t) => t.type == typeFilter).toList();
    }

    _updateStateFromList(txns, false);
  }

  void _updateStateFromList(List<models.Transaction> txns, bool hasNext) {
    final expense = txns
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final income = txns
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    state = state.copyWith(
      transactions: txns,
      hasNext: hasNext,
      monthExpense: expense,
      monthIncome: income,
      monthCount: txns.length,
      loading: false,
    );
  }

  // ── 分页 ──────────────────────────────────────────────────────────────────

  Future<void> loadMore(DateTime month) async {
    if (!state.hasNext || state.loading || !_isLoggedIn) return;
    state = state.copyWith(page: state.page + 1);
    await load(month);
  }

  Future<void> search(DateTime month, String keyword) =>
      load(month, refresh: true, keyword: keyword);

  // ── 图片上传 ─────────────────────────────────────────────────────────────

  Future<String?> uploadReceipt({
    required Uint8List fileBytes,
    required String filename,
    required String mimeType,
  }) async {
    return await _api.uploadReceipt(
      fileBytes: fileBytes,
      filename: filename,
      mimeType: mimeType,
    );
  }

  // ── 写操作 ────────────────────────────────────────────────────────────────

  Future<int> createTransaction({
    required String type,
    required double amount,
    required String currencyCode,
    required int accountId,
    int? toAccountId,
    required int categoryId,
    required int groupId,
    required bool isPrivate,
    String? note,
    required double transactionDate,
    String? receiptUrl,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final data = {
      'type': type,
      'amount': amount,
      'currency_code': currencyCode,
      'exchange_rate': 1.0,
      'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      'category_id': categoryId,
      'group_id': groupId,
      'is_private': isPrivate,
      'note': note,
      'transaction_date': transactionDate,
      'receipt_url': receiptUrl ?? '',
      'items': items,
    };

    if (_isLoggedIn) {
      final txn = await _api.createTransaction(data);
      state = state.copyWith(
        transactions: [txn, ...state.transactions],
        monthExpense: txn.type == 'expense'
            ? state.monthExpense + txn.amount
            : state.monthExpense,
        monthIncome: txn.type == 'income'
            ? state.monthIncome + txn.amount
            : state.monthIncome,
        monthCount: state.monthCount + 1,
      );
      return txn.id;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final localId = await _db.transactionDao.insertTransaction(
        _mapToCompanion(data, groupId, now),
      );
      final month = DateTime.fromMillisecondsSinceEpoch(
        (transactionDate * 1000).toInt(),
      );
      await load(month, refresh: true);
      return localId;
    }
  }

  Future<void> updateTransaction({
    required int id,
    String? type,
    double? amount,
    String? currencyCode,
    int? accountId,
    int? toAccountId,
    int? categoryId,
    bool? isPrivate,
    String? note,
    double? transactionDate,
    String? receiptUrl,
  }) async {
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type;
    if (amount != null) data['amount'] = amount;
    if (currencyCode != null) data['currency_code'] = currencyCode;
    if (accountId != null) data['account_id'] = accountId;
    if (toAccountId != null) data['to_account_id'] = toAccountId;
    if (categoryId != null) data['category_id'] = categoryId;
    if (isPrivate != null) data['is_private'] = isPrivate;
    if (note != null) data['note'] = note;
    if (transactionDate != null) data['transaction_date'] = transactionDate;
    if (receiptUrl != null) data['receipt_url'] = receiptUrl;

    if (_isLoggedIn) {
      final txn = await _api.patchTransaction(id, data);
      final list = state.transactions;
      final idx = list.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final old = list[idx];
        final newList = [...list];
        newList[idx] = txn;
        state = state.copyWith(
          transactions: newList,
          monthExpense:
              state.monthExpense -
              (old.type == 'expense' ? old.amount : 0) +
              (txn.type == 'expense' ? txn.amount : 0),
          monthIncome:
              state.monthIncome -
              (old.type == 'income' ? old.amount : 0) +
              (txn.type == 'income' ? txn.amount : 0),
        );
      }
    } else {
      await _db.transactionDao.updateTransaction(
        id,
        _mapToPatchCompanion(data),
      );
      final t = state.transactions.firstWhere((t) => t.id == id);
      final month = t.date;
      await load(month, refresh: true);
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      if (_isLoggedIn) {
        await _api.deleteTransaction(id);
      } else {
        await _db.transactionDao.softDelete(id);
      }
      final removed = state.transactions.firstWhere(
        (t) => t.id == id,
        orElse: () => throw StateError('not found'),
      );
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
        monthExpense: removed.type == 'expense'
            ? state.monthExpense - removed.amount
            : state.monthExpense,
        monthIncome: removed.type == 'income'
            ? state.monthIncome - removed.amount
            : state.monthIncome,
        monthCount: state.monthCount - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── WS 实时更新 ─────────────────────────────────────────────────────────

  void insertFromWs(Map<String, dynamic> data) {
    try {
      final t = models.Transaction.fromJson(data);
      if (state.transactions.any((e) => e.id == t.id)) return;
      state = state.copyWith(
        transactions: [t, ...state.transactions],
        monthExpense: t.type == 'expense'
            ? state.monthExpense + t.amount
            : state.monthExpense,
        monthIncome: t.type == 'income'
            ? state.monthIncome + t.amount
            : state.monthIncome,
        monthCount: state.monthCount + 1,
      );
    } catch (e) {
      debugPrint('[WS] insertFromWs 失败: $e');
    }
  }

  void updateFromWs(Map<String, dynamic> data) {
    try {
      final updated = models.Transaction.fromJson(data);
      final list = state.transactions;
      final idx = list.indexWhere((t) => t.id == updated.id);
      if (idx == -1) return;
      final old = list[idx];
      final newList = [...list];
      newList[idx] = updated;
      state = state.copyWith(
        transactions: newList,
        monthExpense:
            state.monthExpense -
            (old.type == 'expense' ? old.amount : 0) +
            (updated.type == 'expense' ? updated.amount : 0),
        monthIncome:
            state.monthIncome -
            (old.type == 'income' ? old.amount : 0) +
            (updated.type == 'income' ? updated.amount : 0),
      );
    } catch (e) {
      debugPrint('[WS] updateFromWs 失败: $e');
    }
  }

  void removeById(int id) {
    try {
      final t = state.transactions.firstWhere((e) => e.id == id);
      state = state.copyWith(
        transactions: state.transactions.where((e) => e.id != id).toList(),
        monthExpense: t.type == 'expense'
            ? state.monthExpense - t.amount
            : state.monthExpense,
        monthIncome: t.type == 'income'
            ? state.monthIncome - t.amount
            : state.monthIncome,
        monthCount: state.monthCount - 1,
      );
    } catch (_) {}
  }

  // ── 内部工具 ──────────────────────────────────────────────────────────────

  /// ✅ Fix: 新增可选 catMap 参数，Guest 模式下补充 categoryName/Icon/Color，
  /// 解决列表显示"请选择"的问题。
  models.Transaction _driftRowToTransaction(
    db.Transaction row, {
    Map<int, db.Category>? catMap,
  }) {
    const noDecimal = {'JPY', 'KRW', 'VND'};
    final currency = row.currencyCode;
    double toFloat(int v) =>
        noDecimal.contains(currency) ? v.toDouble() : v / 100.0;

    final cat = catMap?[row.categoryId];

    return models.Transaction(
      id: row.id,
      type: row.type,
      amount: toFloat(row.amount),
      currencyCode: currency,
      baseAmount: toFloat(row.baseAmount),
      exchangeRate: row.exchangeRate / 1_000_000,
      accountId: row.accountId,
      toAccountId: row.toAccountId,
      transferPeerId: row.transferPeerId,
      categoryId: row.categoryId,
      userId: row.userId,
      groupId: row.groupId,
      isPrivate: row.isPrivate,
      note: row.note,
      transactionDate: row.transactionDate.toDouble(),
      createdAt: row.createdAt.toDouble(),
      updatedAt: row.updatedAt.toDouble(),
      isDeleted: row.isDeleted,
      // 补充分类信息
      categoryName: cat?.name,
      categoryIcon: cat?.icon,
      categoryColor: cat?.color,
    );
  }

  db.TransactionsCompanion _mapToCompanion(
    Map<String, dynamic> data,
    int groupId,
    int now,
  ) {
    const noDecimal = {'JPY', 'KRW', 'VND'};
    final currency = data['currency_code'] as String? ?? 'JPY';
    final amount = (data['amount'] as num).toDouble();
    final amountInt = noDecimal.contains(currency)
        ? amount.round()
        : (amount * 100).round();
    final transactionDate =
        ((data['transaction_date'] as num).toDouble() * 1000).toInt() ~/ 1000;

    return db.TransactionsCompanion.insert(
      type: Value(data['type'] as String? ?? 'expense'),
      amount: Value(amountInt),
      currencyCode: Value(currency),
      baseAmount: Value(amountInt),
      exchangeRate: Value(1000000),
      accountId: data['account_id'] as int,
      categoryId: data['category_id'] as int,
      userId: 0,
      groupId: groupId,
      isPrivate: Value(data['is_private'] as bool? ?? false),
      note: Value(data['note'] as String?),
      transactionDate: transactionDate,
      createdAt: now,
      updatedAt: now,
      syncStatus: Value('pending_create'),
    );
  }

  db.TransactionsCompanion _mapToPatchCompanion(Map<String, dynamic> data) {
    return db.TransactionsCompanion(
      note: data.containsKey('note')
          ? Value(data['note'] as String?)
          : const Value.absent(),
      isPrivate: data.containsKey('is_private')
          ? Value(data['is_private'] as bool)
          : const Value.absent(),
      syncStatus: const Value('pending_update'),
    );
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, TransactionsState>(
      TransactionsNotifier.new,
    );
