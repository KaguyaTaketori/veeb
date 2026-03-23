import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/groups_api.dart';
import '../models/account.dart';
import '../database/app_database.dart' show AccountsCompanion;
import 'group_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'accounts_provider.freezed.dart';

@freezed
abstract class AccountsState with _$AccountsState {
  const factory AccountsState({
    @Default([]) List<Account> accounts,
    @Default(false) bool loading,
    String? error,
  }) = _AccountsState;
}

class AccountsNotifier extends Notifier<AccountsState> {
  @override
  AccountsState build() {
    // ✅ 修复：改用 ref.watch 替代 ref.listen
    // ref.listen 只响应「变化」，app 重启时 currentGroupIdProvider 已有初始值
    // 但 listen 回调不触发，导致账户列表永远为空，直到 group 发生新的变化。
    // ref.watch 会在 Provider 首次构建时就拿到当前值并触发加载。
    final groupId = ref.watch(currentGroupIdProvider);
    if (groupId != null) {
      Future.microtask(() => load(groupId));
    }
    return const AccountsState();
  }

  bool get _isLoggedIn =>
      ref.read(authProvider).status == AuthStatus.authenticated;

  AccountsApi get _api => ref.read(accountsApiProvider);

  Future<void> load(int groupId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      List<Account> accounts;
      if (_isLoggedIn) {
        accounts = await ref.read(accountsApiProvider).listAccounts(groupId);
      } else {
        final db = ref.read(appDatabaseProvider);
        final rows = await db.accountDao.watchByGroup(groupId).first;
        accounts = rows
            .map(
              (r) => Account(
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
              ),
            )
            .toList();
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
    required int groupId,
  }) async {
    if (_isLoggedIn) {
      final account = await _api.createAccount({
        'name': name,
        'type': type,
        'currency_code': currencyCode,
        'group_id': groupId,
      });
      state = state.copyWith(accounts: [...state.accounts, account]);
    } else {
      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: name,
          type: Value(type),
          currencyCode: Value(currencyCode),
          groupId: groupId,
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('pending_create'),
        ),
      );
      await load(groupId);
    }
  }
}

final accountsProvider = NotifierProvider<AccountsNotifier, AccountsState>(
  AccountsNotifier.new,
);
