import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../api/transactions_api.dart';
import '../api/groups_api.dart';
import '../models/transaction.dart' as models;
import '../providers/database_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db:  ref.watch(appDatabaseProvider),
    txnApi:     ref.watch(transactionsApiProvider),
    accountApi: ref.watch(accountsApiProvider),
  );
});

enum SyncState { idle, syncing, error }

class SyncService {
  final AppDatabase _db;
  final TransactionsApi _txnApi;
  final AccountsApi _accountApi;

  final _stateCtrl = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateCtrl.stream;

  bool _isSyncing = false;

  SyncService({
    required AppDatabase db,
    required TransactionsApi txnApi,
    required AccountsApi accountApi,
  })  : _db = db,
        _txnApi = txnApi,
        _accountApi = accountApi;

  Timer? _debounceTimer;
  void trySync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _doSync);
  }

  Future<void> syncNow() => _doSync();

  Future<void> fullPull(int groupId) async {
    _stateCtrl.add(SyncState.syncing);
    try {
      final remoteAccounts = await _accountApi.listAccounts(groupId: groupId);
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(
          _db.accounts,
          remoteAccounts.map((a) => AccountsCompanion.insert(
            remoteId:     Value(a.id),
            name:         a.name,
            type:         Value(a.type),
            currencyCode: Value(a.currencyCode),
            groupId:      groupId,
            isActive:     Value(a.isActive),
            createdAt:    a.createdAt.toInt(),
            updatedAt:    a.updatedAt.toInt(),
          )),
        );
      });

      final now = DateTime.now();
      for (var i = 0; i < 3; i++) {
        final month = DateTime(now.year, now.month - i);
        await _pullMonth(groupId, month.year, month.month);
      }

      _stateCtrl.add(SyncState.idle);
    } catch (e) {
      debugPrint('[Sync] fullPull 失败: $e');
      _stateCtrl.add(SyncState.error);
    }
  }

  Future<void> _pullMonth(int groupId, int year, int month) async {
    final response = await _txnApi.listTransactions(
      groupId: groupId,
      year: year,
      month: month,
    );

    final transactions = (response['transactions'] as List? ?? [])
        .map((e) => models.Transaction.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.batch((b) {
      for (final t in transactions) {
        b.insert(
          _db.transactions,
          TransactionsCompanion.insert(
            remoteId:        Value(t.id),
            type:            Value(t.type),
            amount:          Value(t.amount.toInt()),
            currencyCode:    Value(t.currencyCode),
            baseAmount:      Value(t.baseAmount.toInt()),
            exchangeRate:    Value((t.exchangeRate * 1_000_000).toInt()),
            accountId:       t.accountId,
            categoryId:      t.categoryId,
            userId:          t.userId,
            groupId:         groupId,
            transactionDate: t.transactionDate.toInt(),
            createdAt:       t.createdAt.toInt(),
            updatedAt:       t.updatedAt.toInt(),
            syncStatus:      const Value('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _doSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _stateCtrl.add(SyncState.syncing);

    try {
      await _syncAccounts();
      await _syncTransactions();
    } catch (e) {
      debugPrint('[Sync] 同步失败: $e');
      _stateCtrl.add(SyncState.error);
    } finally {
      _isSyncing = false;
      _stateCtrl.add(SyncState.idle);
    }
  }

  Future<void> _syncAccounts() async {
    final pending = await _db.accountDao.getPendingSync();
    for (final account in pending) {
      try {
        switch (account.syncStatus) {
          case 'pending_create':
            final remote = await _accountApi.createAccount(
              name: account.name,
              type: account.type,
              currencyCode: account.currencyCode,
              groupId: account.groupId,
            );
            await _db.accountDao.markSynced(account.id, remote.id);

          case 'pending_update':
            await _accountApi.patchAccount(
              account.remoteId!,
              {'name': account.name, 'type': account.type},
            );
            await (_db.update(_db.accounts)
                  ..where((a) => a.id.equals(account.id)))
                .write(const AccountsCompanion(syncStatus: Value('synced')));
        }
      } catch (e) {
        debugPrint('[Sync] account id=${account.id} 同步失败: $e');
      }
    }
  }

  Future<void> _syncTransactions() async {
    final pending = await _db.transactionDao.getPendingSync();
    for (final txn in pending) {
      try {
        final data = <String, dynamic>{
          'type': txn.type,
          'amount': txn.amount,
          'currency_code': txn.currencyCode,
          'account_id': txn.accountId,
          'category_id': txn.categoryId,
          'group_id': txn.groupId,
          'transaction_date': txn.transactionDate.toDouble(),
        };
        if (txn.note != null) data['note'] = txn.note;

        switch (txn.syncStatus) {
          case 'pending_create':
            final remote = await _txnApi.createTransaction(data);
            await _db.transactionDao.markSynced(txn.id, remote.id);

          case 'pending_update':
            await _txnApi.patchTransaction(txn.remoteId!, data);
            await (_db.update(_db.transactions)
                  ..where((t) => t.id.equals(txn.id)))
                .write(const TransactionsCompanion(syncStatus: Value('synced')));

          case 'pending_delete':
            if (txn.remoteId != null) {
              await _txnApi.deleteTransaction(txn.remoteId!);
            }
            await (_db.delete(_db.transactions)
                  ..where((t) => t.id.equals(txn.id)))
                .go();
        }
      } catch (e) {
        debugPrint('[Sync] transaction id=${txn.id} 同步失败: $e');
      }
    }
  }
}
