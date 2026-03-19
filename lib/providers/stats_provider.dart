// lib/providers/stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/bills_api.dart';
import '../models/bill.dart';

class StatsState {
  final MonthlySummary? summary;
  final bool loading;
  final String? error;

  const StatsState({this.summary, this.loading = false, this.error});

  StatsState copyWith({
    MonthlySummary? summary,
    bool? loading,
    String? error,
  }) =>
      StatsState(
        summary: summary ?? this.summary,
        loading: loading ?? this.loading,
        error: error,
      );
}

class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() => const StatsState();

  BillsApi get _api => ref.watch(billsApiProvider);

  Future<void> load(DateTime month) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _api.getMonthlySummary(
        year: month.year,
        month: month.month,
      );
      state = state.copyWith(
        summary: MonthlySummary.fromJson(data),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(() => StatsNotifier());
