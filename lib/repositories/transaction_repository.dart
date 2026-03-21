// lib/repositories/transaction_repository.dart
class TransactionRepository {
  final AppDatabase _db;
  final TransactionsApi _api;
  final SyncService _sync;

  // ── 写操作（先写本地，后台同步）─────────────────────────────────

  Future<int> create(TransactionsCompanion data) async {
    final id = await _db.into(_db.transactions).insert(
      data.copyWith(syncStatus: const Value('pending_create')),
    );
    unawaited(_sync.trySync());
    return id;
  }

  Future<void> update(int id, TransactionsCompanion data) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(data.copyWith(syncStatus: const Value('pending_update')));
    unawaited(_sync.trySync());
  }

  Future<void> delete(int id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(
          isDeleted: Value(true),
          syncStatus: Value('pending_delete'),
        ));
    unawaited(_sync.trySync());
  }

  // ── 读操作（只读本地）──────────────────────────────────────────

  Stream<List<Transaction>> watchByMonth(int groupId, int year, int month) {
    final start = DateTime(year, month, 1).millisecondsSinceEpoch ~/ 1000;
    final end   = DateTime(year, month + 1, 1).millisecondsSinceEpoch ~/ 1000;
    return (_db.select(_db.transactions)
      ..where((t) =>
          t.groupId.equals(groupId) &
          t.isDeleted.equals(false) &
          t.transactionDate.isBiggerOrEqualValue(start) &
          t.transactionDate.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  // ── 月度汇总 ──────────────────────────────────────────────────

  Future<MonthlyStats> getMonthlyStats(int groupId, int year, int month) async {
    // 直接查本地，无网络延迟
    final start = DateTime(year, month, 1).millisecondsSinceEpoch ~/ 1000;
    final end   = DateTime(year, month + 1, 1).millisecondsSinceEpoch ~/ 1000;

    final totalExp = await (_db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.baseAmount.sum()])
      ..where(
        _db.transactions.groupId.equals(groupId) &
        _db.transactions.type.equals('expense') &
        _db.transactions.isDeleted.equals(false) &
        _db.transactions.transactionDate.isBiggerOrEqualValue(start) &
        _db.transactions.transactionDate.isSmallerThanValue(end),
      ))
      .map((r) => r.read(_db.transactions.baseAmount.sum()) ?? 0)
      .getSingle();

    return MonthlyStats(totalExpense: totalExp);
  }
}