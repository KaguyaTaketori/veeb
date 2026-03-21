import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Transaction>> watchByAccount(int accountId) =>
      (select(transactions)
            ..where((t) => t.accountId.equals(accountId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .watch();

  Stream<List<Transaction>> watchByGroup(int groupId) =>
      (select(transactions)
            ..where((t) => t.groupId.equals(groupId) & t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .watch();

  Stream<List<Transaction>> watchByMonth(int groupId, int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth   = DateTime(year, month + 1, 0, 23, 59, 59);
    final startTs = startOfMonth.millisecondsSinceEpoch ~/ 1000;
    final endTs   = endOfMonth.millisecondsSinceEpoch ~/ 1000;

    return (select(transactions)
          ..where((t) =>
              t.groupId.equals(groupId) &
              t.isDeleted.equals(false) &
              t.transactionDate.isBiggerOrEqualValue(startTs) &
              t.transactionDate.isSmallerOrEqualValue(endTs))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  Future<Transaction?> getById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getPendingSync() =>
      (select(transactions)..where((t) => t.syncStatus.isNotValue('synced'))).get();

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(
        entry.copyWith(syncStatus: const Value('pending_create')),
      );

  Future<void> updateTransaction(int id, TransactionsCompanion entry) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        entry.copyWith(syncStatus: const Value('pending_update')),
      );

  Future<void> softDelete(int id) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        const TransactionsCompanion(
          isDeleted: Value(true),
          syncStatus: Value('pending_delete'),
        ),
      );

  Future<void> markSynced(int localId, int remoteId) =>
      (update(transactions)..where((t) => t.id.equals(localId))).write(
        TransactionsCompanion(
          remoteId:   Value(remoteId),
          syncStatus: const Value('synced'),
        ),
      );

  Future<List<TransactionItem>> getItems(int transactionId) =>
      (select(transactionItems)
            ..where((i) => i.transactionId.equals(transactionId))
            ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
          .get();

  Future<int> insertItem(TransactionItemsCompanion entry) =>
      into(transactionItems).insert(entry);

  Future<void> deleteItems(int transactionId) =>
      (delete(transactionItems)..where((i) => i.transactionId.equals(transactionId))).go();
}
