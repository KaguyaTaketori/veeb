import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/groups_api.dart';
import '../models/account.dart';
import '../database/tables.dart' as db_tables;
import '../database/app_database.dart' show AccountsCompanion;
import 'group_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

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
    ref.listen(currentGroupIdProvider, (_, groupId) {
      if (groupId != null) load(groupId);
    });
    return const AccountsState();
  }

  bool get _isLoggedIn =>
      ref.read(authProvider).status == AuthStatus.authenticated;

  AccountsApi get _api => ref.read(accountsApiProvider);

  Future<void> load(int groupId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      List<Account> accounts;
      if (_isLoggedIn) {
        accounts = await ref.read(accountsApiProvider).listAccounts(groupId: groupId);
      } else {
        final db = ref.read(appDatabaseProvider);
        final rows = await db.accountDao.watchByGroup(groupId).first;
        accounts = rows.map((r) => Account(
          id: r.id,
          name: r.name,
          type: r.type,
          currencyCode: r.currencyCode,
          groupId: r.groupId,
          balanceCache: r.balanceCache,
          balanceUpdatedAt: r.balanceUpdatedAt?.toDouble(),
          isActive: r.isActive,
          createdAt: r.createdAt.toDouble(),
          updatedAt: r.updatedAt.toDouble(),
        )).toList();
      }
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
    if (_isLoggedIn) {
      final account = await _api.createAccount(
        name: name, type: type, currencyCode: currencyCode, groupId: groupId,
      );
      state = state.copyWith(accounts: [...state.accounts, account]);
    } else {
      final db  = ref.read(appDatabaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name:         name,
          type:         Value(type),
          currencyCode: Value(currencyCode),
          groupId:      groupId,
          createdAt:    now,
          updatedAt:    now,
          syncStatus:   const Value('pending_create'),
        ),
      );
      // 刷新本地列表
      await load(groupId);
    }
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, AccountsState>(AccountsNotifier.new);