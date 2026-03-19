// lib/providers/bills_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/bills_api.dart';
import '../models/bill.dart';

class BillsState {
  final List<Bill> bills;
  final bool loading;
  final String? error;
  final bool hasNext;
  final int page;
  final double monthTotal;
  final int monthCount;
  final String keyword;

  const BillsState({
    this.bills = const [],
    this.loading = false,
    this.error,
    this.hasNext = false,
    this.page = 1,
    this.monthTotal = 0,
    this.monthCount = 0,
    this.keyword = '',
  });

  BillsState copyWith({
    List<Bill>? bills,
    bool? loading,
    String? error,
    bool? hasNext,
    int? page,
    double? monthTotal,
    int? monthCount,
    String? keyword,
  }) =>
      BillsState(
        bills: bills ?? this.bills,
        loading: loading ?? this.loading,
        error: error,
        hasNext: hasNext ?? this.hasNext,
        page: page ?? this.page,
        monthTotal: monthTotal ?? this.monthTotal,
        monthCount: monthCount ?? this.monthCount,
        keyword: keyword ?? this.keyword,
      );
}

class BillsNotifier extends Notifier<BillsState> {
  // ── 请求序列号：每次发起新请求自增，响应回来时校验是否仍是最新请求 ────
  int _seq = 0;

  @override
  BillsState build() => const BillsState();

  BillsApi get _api => ref.watch(billsApiProvider);

  Future<void> load(
    DateTime month, {
    bool refresh = false,
    String? keyword,
  }) async {
    final page = refresh ? 1 : state.page;
    final kw = keyword ?? state.keyword;

    // 自增序列号，标记本次请求
    final mySeq = ++_seq;

    state = state.copyWith(
      loading: true,
      error: null,
      page: page,
      keyword: kw,
      bills: refresh ? [] : state.bills,
    );

    try {
      final data = await _api.listBills(
        page: page,
        year: month.year,
        month: month.month,
        keyword: kw.isEmpty ? null : kw,
      );

      // 序列号不匹配说明有更新的请求已发出，丢弃本次响应
      if (mySeq != _seq) return;

      final newBills = (data['bills'] as List)
          .map((e) => Bill.fromJson(e as Map<String, dynamic>))
          .toList();
      final merged = refresh ? newBills : [...state.bills, ...newBills];

      // 优先使用后端返回的 total，作为正确的过滤后总数
      final total = (data['total'] as num?)?.toDouble() ??
          merged.fold<double>(0.0, (s, b) => s + b.amount);
      final monthTotal = merged.fold<double>(0.0, (s, b) => s + b.amount);

      state = state.copyWith(
        bills: merged,
        hasNext: data['has_next'] as bool? ?? false,
        monthTotal: monthTotal,
        monthCount: merged.length,
        loading: false,
      );
    } catch (e) {
      if (mySeq != _seq) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore(DateTime month) async {
    if (!state.hasNext || state.loading) return;
    state = state.copyWith(page: state.page + 1);
    await load(month);
  }

  Future<void> search(DateTime month, String keyword) async {
    await load(month, refresh: true, keyword: keyword);
  }

  Future<void> deleteBill(int billId) async {
    try {
      await _api.deleteBill(billId);
      state = state.copyWith(
        bills: state.bills.where((b) => b.id != billId).toList(),
        monthCount: state.monthCount - 1,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final billsProvider =
    NotifierProvider<BillsNotifier, BillsState>(() => BillsNotifier());