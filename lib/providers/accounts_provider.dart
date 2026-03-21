import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/groups_api.dart';
import '../models/account.dart';
import 'group_provider.dart';
 
class AccountsState {
  final List<Account> accounts;
  final bool          loading;
  final String?       error;
 
  const AccountsState({
    this.accounts = const [],
    this.loading  = false,
    this.error,
  });
 
  AccountsState copyWith({
    List<Account>? accounts,
    bool?          loading,
    String?        error,
    bool           clearError = false,
  }) =>
      AccountsState(
        accounts: accounts ?? this.accounts,
        loading:  loading  ?? this.loading,
        error:    clearError ? null : (error ?? this.error),
      );
}
 
class AccountsNotifier extends Notifier<AccountsState> {
  @override
  AccountsState build() {
    // 当 group 加载完后自动加载账户
    ref.listen(currentGroupIdProvider, (_, groupId) {
      if (groupId != null) load(groupId);
    });
    return const AccountsState();
  }
 
  AccountsApi get _api => ref.read(accountsApiProvider);
 
  Future<void> load(int groupId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final accounts = await _api.listAccounts(groupId: groupId);
      state = state.copyWith(accounts: accounts, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
 
  Future<void> createAccount({
    required String name,
    required String type,
    required String currencyCode,
    required int    groupId,
  }) async {
    final account = await _api.createAccount(
      name: name, type: type, currencyCode: currencyCode, groupId: groupId,
    );
    state = state.copyWith(accounts: [...state.accounts, account]);
  }
}
 
final accountsProvider =
    NotifierProvider<AccountsNotifier, AccountsState>(AccountsNotifier.new);