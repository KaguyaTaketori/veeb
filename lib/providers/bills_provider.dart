// lib/providers/bills_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/bills_api.dart';
import '../models/bill.dart';

// ── 状态定义 ──────────────────────────────────────────────

class BillsState {
  final List<Bill> bills;
  final bool loading;
  final String? error;
  final bool hasNext;
  final int page;
  final double monthTotal;
  final int monthCount;

  const BillsState({
    this.bills = const [],
    this.loading = false,
    this.error,
    this.hasNext = false,
    this.page = 1,
    this.monthTotal = 0,
    this.monthCount = 0,
  });

  BillsState copyWith({
    List<Bill>? bills,
    bool? loading,
    String? error,
    bool? hasNext,
    int? page,
    double? monthTotal,
    int? monthCount,
  }) =>
      BillsState(
        bills: bills ?? this.bills,
        loading: loading ?? this.loading,
        error: error,                   // null 可清空 error
        hasNext: hasNext ?? this.hasNext,
        page: page ?? this.page,
        monthTotal: monthTotal ?? this.monthTotal,
        monthCount: monthCount ?? this.monthCount,
      );
}

// ── Notifier ──────────────────────────────────────────────

class BillsNotifier extends StateNotifier<BillsState> {
  final BillsApi _api;

  BillsNotifier(this._api) : super(const BillsState());

  // ✅ 修复 #7：setState 合并为 2 次（开始 + 结束），在 Notifier 中天然避免
  Future<void> load(DateTime month, {bool refresh = false}) async {
    final page = refresh ? 1 : state.page;
    state = state.copyWith(
      loading: true,
      error: null,
      page: page,
      bills: refresh ? [] : state.bills,
    );

    try {
      final data = await _api.listBills(
        page: page,
        year: month.year,
        month: month.month,
      );
      final newBills = (data['bills'] as List)
          .map((e) => Bill.fromJson(e as Map<String, dynamic>))
          .toList();
      final merged = refresh ? newBills : [...state.bills, ...newBills];
      final total = (data['month_total'] as num?)?.toDouble() ??
          merged.fold<double>(0.0, (s, b) => s + b.amount);

      state = state.copyWith(
        bills: merged,
        hasNext: data['has_next'] as bool? ?? false,
        monthTotal: total,
        monthCount: data['month_count'] as int? ?? merged.length,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore(DateTime month) async {
    if (!state.hasNext || state.loading) return;
    state = state.copyWith(page: state.page + 1);
    await load(month);
  }
}

// ── Provider ──────────────────────────────────────────────

final billsProvider =
    StateNotifierProvider<BillsNotifier, BillsState>((ref) {
  return BillsNotifier(ref.watch(billsApiProvider));
});