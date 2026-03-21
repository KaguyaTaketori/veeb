import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
 
part 'account_dao.g.dart';
 
@DriftAccessor(tables: [Accounts, Transactions])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);
 
  Stream<List<Account>> watchByGroup(int groupId) =>
      (select(accounts)
            ..where((a) => a.groupId.equals(groupId) & a.isActive.equals(true))
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .watch();
 
  Future<int> insertAccount(AccountsCompanion entry) =>
      into(accounts).insert(
        entry.copyWith(syncStatus: const Value('pending_create')),
      );
 
  Future<void> updateAccount(int id, AccountsCompanion entry) =>
      (update(accounts)..where((a) => a.id.equals(id))).write(
        entry.copyWith(syncStatus: const Value('pending_update')),
      );
 
  Future<List<Account>> getPendingSync() =>
      (select(accounts)..where((a) => a.syncStatus.isNotValue('synced'))).get();
 
  Future<void> markSynced(int localId, int remoteId) =>
      (update(accounts)..where((a) => a.id.equals(localId))).write(
        AccountsCompanion(
          remoteId:   Value(remoteId),
          syncStatus: const Value('synced'),
        ),
      );
 
  /// 更新余额缓存（从服务端拉取后刷新）
  Future<void> updateBalanceCache(int id, int balance) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        balanceCache:     Value(balance),
        balanceUpdatedAt: Value(now),
      ),
    );
  }
}