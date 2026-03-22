// lib/providers/monthly_trend_provider.dart
//
// 月度趋势数据 Provider
//
// 加载最近 N 个月的收支汇总，供 VeeMonthlyTrendCard 使用。
// 已登录：并发请求 API（getMonthlySummary × N）
// Guest  ：从本地 DB 按月聚合

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transactions_api.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/database_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 数据模型
// ─────────────────────────────────────────────────────────────────────────────

class MonthPoint {
  final int year;
  final int month;
  final double expense;
  final double income;

  const MonthPoint({
    required this.year,
    required this.month,
    required this.expense,
    required this.income,
  });

  /// 短标签，如 "1月" / "12月"
  String get label => '$month月';

  DateTime get date => DateTime(year, month);
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// 以 [anchor]（当月）为基准，向前加载 [months] 个月的趋势数据。
/// 默认取最近 6 个月（含当月）。
final monthlyTrendProvider =
    FutureProvider.family<List<MonthPoint>, ({DateTime anchor, int months})>((
      ref,
      params,
    ) async {
      final groupId = ref.watch(currentGroupIdProvider);
      if (groupId == null) return [];

      final isLoggedIn =
          ref.watch(authProvider).status == AuthStatus.authenticated;

      final anchor = params.anchor;
      final count = params.months;

      // 生成目标月份列表（从最旧 → 最新）
      final months = List.generate(count, (i) {
        final offset = count - 1 - i;
        return DateTime(anchor.year, anchor.month - offset);
      });

      if (isLoggedIn) {
        return _loadFromApi(ref, groupId, months);
      } else {
        return _loadFromLocal(ref, groupId, months);
      }
    });

// ── 已登录：并发 API ──────────────────────────────────────────────────────────

Future<List<MonthPoint>> _loadFromApi(
  Ref ref,
  int groupId,
  List<DateTime> months,
) async {
  final api = ref.read(transactionsApiProvider);

  final results = await Future.wait(
    months.map((m) async {
      try {
        final stat = await api.getMonthlySummary(
          groupId: groupId,
          year: m.year,
          month: m.month,
        );
        return MonthPoint(
          year: m.year,
          month: m.month,
          expense: stat.totalExpense,
          income: stat.totalIncome,
        );
      } catch (_) {
        return MonthPoint(year: m.year, month: m.month, expense: 0, income: 0);
      }
    }),
  );

  return results;
}

// ── Guest：本地 DB 聚合 ────────────────────────────────────────────────────────

Future<List<MonthPoint>> _loadFromLocal(
  Ref ref,
  int groupId,
  List<DateTime> months,
) async {
  final db = ref.read(appDatabaseProvider);
  const noDecimal = {'JPY', 'KRW', 'VND'};

  final results = await Future.wait(
    months.map((m) async {
      final rows = await db.transactionDao
          .watchByMonth(groupId, m.year, m.month)
          .first;

      double expense = 0;
      double income = 0;

      for (final row in rows) {
        final currency = row.currencyCode;
        final amount = noDecimal.contains(currency)
            ? row.baseAmount.toDouble()
            : row.baseAmount / 100.0;

        if (row.type == 'expense') expense += amount;
        if (row.type == 'income') income += amount;
      }

      return MonthPoint(
        year: m.year,
        month: m.month,
        expense: expense,
        income: income,
      );
    }),
  );

  return results;
}
