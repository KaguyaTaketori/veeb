import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transactions_api.dart';
import '../models/transaction.dart';
import '../providers/group_provider.dart';
 
class StatsState {
  final MonthlyStat? summary;
  final bool         loading;
  final String?      error;
 
  const StatsState({this.summary, this.loading = false, this.error});
 
  StatsState copyWith({
    MonthlyStat? summary,
    bool?        loading,
    String?      error,
  }) =>
      StatsState(
        summary: summary ?? this.summary,
        loading: loading ?? this.loading,
        error:   error,
      );
}
 
class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() => const StatsState();
 
  TransactionsApi get _api => ref.watch(transactionsApiProvider);
 
  Future<void> load(DateTime month) async {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) return;
 
    state = state.copyWith(loading: true, error: null);
    try {
      final summary = await _api.getMonthlySummary(
        groupId: groupId,
        year:    month.year,
        month:   month.month,
      );
      state = state.copyWith(summary: summary, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
 
final statsProvider =
    NotifierProvider<StatsNotifier, StatsState>(StatsNotifier.new);