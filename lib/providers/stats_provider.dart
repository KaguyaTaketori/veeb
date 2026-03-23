// lib/providers/stats_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vee_app/utils/currency.dart';
import '../api/transactions_api.dart';
import '../database/app_database.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/database_provider.dart';

class StatsState {
  final MonthlyStat? summary;
  final bool loading;
  final String? error;

  const StatsState({this.summary, this.loading = false, this.error});

  StatsState copyWith({
    MonthlyStat? summary,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => StatsState(
    summary: summary ?? this.summary,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() => const StatsState();

  bool get _isLoggedIn =>
      ref.read(authProvider).status == AuthStatus.authenticated;

  TransactionsApi get _api => ref.read(transactionsApiProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> load(DateTime month) async {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;

    state = state.copyWith(loading: true, clearError: true);

    try {
      if (_isLoggedIn) {
        await _loadFromApi(groupId, month);
      } else {
        await _loadFromLocal(groupId, month);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── 已登录：从 API 拉取 ────────────────────────────────────────────────

  Future<void> _loadFromApi(int groupId, DateTime month) async {
    final summary = await _api.getMonthlySummary(
      groupId: groupId,
      year: month.year,
      month: month.month,
    );
    state = state.copyWith(summary: summary, loading: false);
  }

  // ── Guest 模式：直接查本地 Drift DB ──────────────────────────────────────

  Future<void> _loadFromLocal(int groupId, DateTime month) async {
    // 从本地 DB 查该月所有流水
    final rawList = await _db.transactionDao
        .watchByMonth(groupId, month.year, month.month)
        .first;

    if (rawList.isEmpty) {
      state = state.copyWith(
        summary: MonthlyStat(
          year: month.year,
          month: month.month,
          totalExpense: 0,
          totalIncome: 0,
          net: 0,
          count: 0,
          byCategory: [],
          byCurrency: [],
        ),
        loading: false,
      );
      return;
    }

    // 计算汇总
    const noDecimal = {'JPY', 'KRW', 'VND'};
    double totalExpense = 0;
    double totalIncome = 0;

    // 按分类聚合
    final Map<int, _CategoryAgg> byCategory = {};

    for (final row in rawList) {
      final amount = intToFloat(row.amount, row.currencyCode);
      final baseAmt = intToFloat(row.baseAmount, row.currencyCode);

      if (row.type == 'expense') totalExpense += baseAmt;
      if (row.type == 'income') totalIncome += baseAmt;

      if (row.type == 'expense') {
        final agg = byCategory.putIfAbsent(
          row.categoryId,
          () => _CategoryAgg(categoryId: row.categoryId),
        );
        agg.total += amount;
        agg.count++;
      }
    }

    // 从本地 categories 表取名称/图标
    final cats = await _db.categoryDao.getAvailable(groupId);
    final catMap = {for (final c in cats) c.id: c};

    final byCategoryOut = byCategory.values.map((agg) {
      final cat = catMap[agg.categoryId];
      return CategoryStat(
        categoryId: agg.categoryId,
        name: cat?.name ?? '未知',
        icon: cat?.icon ?? '📦',
        color: cat?.color ?? '#95A5A6',
        total: agg.total,
        count: agg.count,
        percent: totalExpense > 0 ? agg.total / totalExpense * 100 : 0,
      );
    }).toList()..sort((a, b) => b.total.compareTo(a.total));

    // 按货币聚合（简化：只取第一种货币）
    final currencies = <String, double>{};
    for (final row in rawList) {
      final amount = intToFloat(row.amount, row.currencyCode);
      currencies.update(
        row.currencyCode,
        (v) => v + amount,
        ifAbsent: () => amount,
      );
    }
    final byCurrencyOut = currencies.entries
        .map((e) => {'currency': e.key, 'total': e.value})
        .toList();

    state = state.copyWith(
      loading: false,
      summary: MonthlyStat(
        year: month.year,
        month: month.month,
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        net: totalIncome - totalExpense,
        count: rawList.length,
        byCategory: byCategoryOut,
        byCurrency: byCurrencyOut,
      ),
    );
  }
}

// 内部聚合辅助类
class _CategoryAgg {
  final int categoryId;
  double total = 0;
  int count = 0;
  _CategoryAgg({required this.categoryId});
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(
  StatsNotifier.new,
);
