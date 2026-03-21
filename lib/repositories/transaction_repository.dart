// lib/repositories/transaction_repository.dart
import 'dart:async';
import 'package:drift/drift.dart';
import '../api/transactions_api.dart';
import '../database/app_database.dart';
import '../services/sync_service.dart';

class TransactionRepository {
  final AppDatabase _db;
  final TransactionsApi _api;
  final SyncService _sync;

  TransactionRepository({
    required AppDatabase db,
    required TransactionsApi api,
    required SyncService sync,
  })  : _db = db,
        _api = api,
        _sync = sync;

  Future<int> create(TransactionsCompanion data) async {
    final id = await _db.into(_db.transactions).insert(
      data.copyWith(syncStatus: const Value('pending_create')),
    );
    _sync.trySync();
    return id;
  }

  Future<void> update(int id, TransactionsCompanion data) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(data.copyWith(syncStatus: const Value('pending_update')));
    _sync.trySync();
  }

  Future<void> delete(int id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(
          isDeleted: Value(true),
          syncStatus: Value('pending_delete'),
        ));
    _sync.trySync();
  }

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

  Future<MonthlyStats> getMonthlyStats(int groupId, int year, int month) async {
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

class MonthlyStats {
  final int totalExpense;
  const MonthlyStats({required this.totalExpense});
}
