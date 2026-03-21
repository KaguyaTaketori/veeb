// lib/providers/bills_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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

  void insertBillFromWs(Map<String, dynamic> data) {
    try {
      final bill = Bill.fromJson(data);
      // 避免重复插入（同一 bill_id）
      final exists = state.bills.any((b) => b.id == bill.id);
      if (exists) return;
      state = state.copyWith(
        bills:      [bill, ...state.bills],
        monthTotal: state.monthTotal + bill.amount,
        monthCount: state.monthCount + 1,
      );
    } catch (e) {
      debugPrint('[WS] insertBillFromWs 解析失败: $e');
    }
  }
 
  /// WS 推送：更新列表中已有账单
  void updateBillFromWs(Map<String, dynamic> data) {
    try {
      final updated = Bill.fromJson(data);
      final oldList = state.bills;
      final idx = oldList.indexWhere((b) => b.id == updated.id);
      if (idx == -1) return;
      final old = oldList[idx];
      final newList = [...oldList];
      newList[idx] = updated;
      state = state.copyWith(
        bills:      newList,
        monthTotal: state.monthTotal - old.amount + updated.amount,
      );
    } catch (e) {
      debugPrint('[WS] updateBillFromWs 解析失败: $e');
    }
  }
 
  /// WS 推送：从列表移除已删除账单
  void removeBillById(int billId) {
    final old = state.bills.firstWhere(
      (b) => b.id == billId,
      orElse: () => throw StateError('not found'),
    );
    state = state.copyWith(
      bills:      state.bills.where((b) => b.id != billId).toList(),
      monthTotal: state.monthTotal - old.amount,
      monthCount: state.monthCount - 1,
    );
  }

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

  // ── OCR ───────────────────────────────────────────────────────────────────

  Future<Bill> ocrBill(String imageBase64, String mimeType) async {
    final data = await _api.ocrBill(imageBase64, mimeType);
    return Bill.fromJson(data);
  }

  // ── 写操作 ─────────────────────────────────────────────────────────────

  Future<int> createBill({
    required double amount,
    required String currency,
    String? category,
    String? merchant,
    String? description,
    required String billDate,
    String? receiptUrl,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final data = {
      'amount': amount,
      'currency': currency,
      'category': category,
      'merchant': merchant,
      'description': description,
      'bill_date': billDate,
      'receipt_url': receiptUrl ?? '',
      'items': items,
    };

    final response = await _api.createBill(data);
    final bill = Bill.fromJson(response);
    state = state.copyWith(
      bills: [bill, ...state.bills],
      monthTotal: state.monthTotal + bill.amount,
      monthCount: state.monthCount + 1,
    );
    return bill.id;
  }

  Future<void> updateBill({
    required int id,
    double? amount,
    String? currency,
    String? category,
    String? merchant,
    String? description,
    String? billDate,
    String? receiptUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (amount != null) updates['amount'] = amount;
    if (currency != null) updates['currency'] = currency;
    if (category != null) updates['category'] = category;
    if (merchant != null) updates['merchant'] = merchant;
    if (description != null) updates['description'] = description;
    if (billDate != null) updates['bill_date'] = billDate;
    if (receiptUrl != null) updates['receipt_url'] = receiptUrl;

    final response = await _api.patchBill(id, updates);
    final updated = Bill.fromJson(response);
    final idx = state.bills.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final old = state.bills[idx];
      final newList = [...state.bills];
      newList[idx] = updated;
      state = state.copyWith(
        bills: newList,
        monthTotal: state.monthTotal - old.amount + updated.amount,
      );
    }
  }
}

final billsProvider =
    NotifierProvider<BillsNotifier, BillsState>(() => BillsNotifier());