import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vee_app/models/transaction.dart' as models;
import '../api/transactions_api.dart';
import '../database/app_database.dart' as db;
import '../models/transaction.dart';
import 'auth_provider.dart';
import 'group_provider.dart';
import 'database_provider.dart';
import '../database/mappers/transaction_mapper.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'transactions_provider.freezed.dart';

// ── State ────────────────────────────────────────────────────────────────────

@freezed
abstract class TransactionsState with _$TransactionsState {
  const factory TransactionsState({
    @Default([]) List<Transaction> transactions,
    @Default(false) bool loading,
    String? error,
    @Default(false) bool hasNext,
    @Default(1) int page,
    @Default(0.0) double monthExpense,
    @Default(0.0) double monthIncome,
    @Default(0) int monthCount,
    @Default('') String keyword,
    String? typeFilter,
  }) = _TransactionsState;
}

const _keepValue = _KeepValue();

class _KeepValue {
  const _KeepValue();
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

  // ── 加载
  //
  // typeFilter 使用 Object? 加哨兵，解决 Dart 中 null 不能区分
  // "未传"和"明确传 null" 的问题：
  //   - 不传（默认 _keepValue） → 保留上次的筛选（翻页、搜索场景）
  //   - 传 null               → 清除筛选（合计 tab）
  //   - 传 'expense'等        → 设置新筛选
  //
  // keyword 同理。

  Future<void> load(
    DateTime month, {
    bool refresh = false,
    Object? keyword = _keepValue,
    Object? typeFilter = _keepValue,
    int? accountId,
  }) async {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;

    final kw = identical(keyword, _keepValue)
        ? state.keyword
        : (keyword as String?) ?? '';

    final String? type = identical(typeFilter, _keepValue)
        ? state
              .typeFilter // 未传 → 保留旧值
        : typeFilter as String?; // 传 null = 合计，传字符串 = 筛选

    final page = refresh ? 1 : state.page;
    final mySeq = ++_seq;

    // 立即更新 loading 状态；保留合计数字以避免切换 tab 时闪烁归零
    state = state.copyWith(
      transactions: refresh ? [] : state.transactions,
      loading: true,
      error: null, // 清空错误
      page: page,
      keyword: kw,
      typeFilter: type,
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

  // ── API 模式 ──────────────────────────────────────────────────────────────
  //
  // 有类型筛选时，并行拉整月汇总，使合计数字始终反映全月数据。

  Future<void> _loadFromApi(
    DateTime month, {
    required int groupId,
    required int page,
    required String keyword,
    required String? typeFilter,
    required int? accountId,
    required int mySeq,
  }) async {
    final listFuture = _api.listTransactions(
      groupId,
      page: page,
      year: month.year,
      month: month.month,
      keyword: keyword.isEmpty ? null : keyword,
      type: typeFilter,
      accountId: accountId,
    );

    // 有筛选时并行拉整月汇总
    final summaryFuture = typeFilter != null
        ? _api
              .getMonthlySummary(groupId, year: month.year, month: month.month)
              .then<models.MonthlyStat?>((s) => s)
              .catchError((_) => null as models.MonthlyStat?)
        : Future<models.MonthlyStat?>.value(null);

    final data = await listFuture as Map<String, dynamic>;
    if (mySeq != _seq) return;

    final fetched = (data['transactions'] as List)
        .map((e) => models.Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final merged = (state.transactions.isEmpty || page == 1)
        ? fetched
        : [...state.transactions, ...fetched];
    final hasNext = data['has_next'] as bool? ?? false;

    final summary = await summaryFuture;
    if (mySeq != _seq) return;

    if (summary != null) {
      state = state.copyWith(
        transactions: merged,
        hasNext: hasNext,
        monthExpense: summary.totalExpense,
        monthIncome: summary.totalIncome,
        monthCount: summary.count,
        loading: false,
      );
    } else {
      _updateStateFromList(merged, hasNext);
    }
  }

  // ── 本地 DB 模式（Guest）──────────────────────────────────────────────────
  //
  // 先对全月流水计算合计（筛选前），再对展示列表应用筛选。

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

    final cats = await _db.categoryDao.getAvailable(groupId);
    final catMap = {for (final c in cats) c.id: c};

    final allTxns = rawList
        .map((row) => driftRowToTransaction(row, catMap: catMap))
        .toList();

    // 合计：全月数据（筛选前）
    final expense = allTxns
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final income = allTxns
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final count = allTxns.length;

    // 展示列表：应用筛选
    var display = allTxns;
    if (keyword.isNotEmpty) {
      final kw = keyword.toLowerCase();
      display = display
          .where(
            (t) =>
                (t.note?.toLowerCase().contains(kw) ?? false) ||
                (t.categoryName?.toLowerCase().contains(kw) ?? false) ||
                (t.payee?.toLowerCase().contains(kw) ?? false),
          )
          .toList();
    }
    if (typeFilter != null) {
      display = display.where((t) => t.type == typeFilter).toList();
    }

    if (mySeq != _seq) return;

    state = state.copyWith(
      transactions: display,
      hasNext: false,
      monthExpense: expense,
      monthIncome: income,
      monthCount: count,
      loading: false,
    );
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

  // ── 翻页：不传 typeFilter/keyword → 哨兵保留旧值 ──────────────────────────

  Future<void> loadMore(DateTime month) async {
    if (!state.hasNext || state.loading || !_isLoggedIn) return;
    state = state.copyWith(page: state.page + 1);
    await load(month); // 不传 typeFilter → 哨兵 → 保留旧值
  }

  // ── 搜索：保留当前类型筛选 ────────────────────────────────────────────────

  Future<void> search(DateTime month, String keyword) =>
      load(month, refresh: true, keyword: keyword);
  // typeFilter 不传 → 哨兵 → 保留旧值

  // ── 图片上传 ─────────────────────────────────────────────────────────────

  Future<String?> uploadReceipt({
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
  }) async {
    final resp = await _api.uploadReceiptRaw(fileBytes, filename: filename);
    return (resp as Map<String, dynamic>)['receipt_url'] as String;
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
    String? payee,
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
      if (payee != null && payee.isNotEmpty) 'payee': payee,
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
    String? payee,
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
    if (payee != null) data['payee'] = payee;
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
      await load(t.date, refresh: true);
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

  // ── WS 实时更新 ──────────────────────────────────────────────────────────

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
      payee: Value(data['payee'] as String?),
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
      payee: data.containsKey('payee')
          ? Value(data['payee'] as String?)
          : const Value.absent(),
      syncStatus: const Value('pending_update'),
    );
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, TransactionsState>(
      TransactionsNotifier.new,
    );
