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
    categoryApi: ref.watch(categoriesApiProvider),
  );
});

enum SyncState { idle, syncing, error }

class SyncService {
  final AppDatabase _db;
  final TransactionsApi _txnApi;
  final AccountsApi _accountApi;
  final CategoriesApi    _categoryApi;

  final _stateCtrl = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateCtrl.stream;

  bool _isSyncing = false;

  SyncService({
    required AppDatabase db,
    required TransactionsApi txnApi,
    required AccountsApi accountApi,
    required CategoriesApi categoryApi,
  })  : _db = db,
        _txnApi = txnApi,
        _accountApi = accountApi,
        _categoryApi = categoryApi;

  Timer? _debounceTimer;
  void trySync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _doSync);
  }

  Future<void> syncNow() => _doSync();

  Future<void> fullPull(int groupId) async {
  _stateCtrl.add(SyncState.syncing);
  try {
    // 1. 拉账户（原有）
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
          syncStatus:   const Value('synced'),
        )),
      );
    });

    // 2. 拉分类，按名称匹配写回 remoteId ← 新增
    final remoteCategories =
        await _categoryApi.listCategories(groupId: groupId);
    for (final remote in remoteCategories) {
      // 先找已有的本地记录（按名称匹配）
      final local = await (_db.select(_db.categories)
            ..where((c) => c.name.equals(remote.name)))
          .getSingleOrNull();

      if (local != null) {
        // 已存在：更新 remoteId
        await (_db.update(_db.categories)
              ..where((c) => c.id.equals(local.id)))
            .write(CategoriesCompanion(
              remoteId:   Value(remote.id),
              syncStatus: const Value('synced'),
            ));
      } else {
        // 不存在：插入
        await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            remoteId:  Value(remote.id),
            name:      remote.name,
            icon:      Value(remote.icon),
            color:     Value(remote.color),
            type:      Value(remote.type),
            isSystem:  Value(remote.isSystem),
            groupId:   Value(remote.groupId ?? groupId),
            sortOrder: Value(remote.sortOrder),
            syncStatus: const Value('synced'),
          ),
        );
      }
    }

    // 3. 拉近三个月流水（原有）
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
      await _syncCategories(); 
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
        final remoteGroupId =
            await _resolveRemoteGroupId(account.groupId);
        if (remoteGroupId == 0) continue; // group 还没同步，跳过

        switch (account.syncStatus) {
          case 'pending_create':
            final remote = await _accountApi.createAccount(
              name:         account.name,
              type:         account.type,
              currencyCode: account.currencyCode,
              groupId:      remoteGroupId, // ← 用 remoteGroupId
            );
            await _db.accountDao.markSynced(account.id, remote.id);
          case 'pending_update':
            await _accountApi.patchAccount(
              account.remoteId!,
              {'name': account.name},
            );
            await (_db.update(_db.accounts)
                  ..where((a) => a.id.equals(account.id)))
                .write(const AccountsCompanion(
                    syncStatus: Value('synced')));
        }
      } catch (e) {
        debugPrint('[Sync] account id=${account.id} 同步失败: $e');
      }
    }
  }

  Future<void> _syncCategories() async {
    final pending = await _db.categoryDao.getPendingSync();
    for (final cat in pending) {
      if (cat.isSystem) continue; // 系统分类不上传
      try {
        final groupId = await _resolveRemoteGroupId(cat.groupId ?? 0);
        if (groupId == 0) continue; // group 还没同步，跳过

        switch (cat.syncStatus) {
          case 'pending_create':
            final remote = await _categoryApi.createCategory({
              'name':       cat.name,
              'icon':       cat.icon ?? '📦',
              'color':      cat.color ?? '#95A5A6',
              'type':       cat.type,
              'group_id':   groupId,
              'sort_order': cat.sortOrder,
            });
            // 写回 remoteId
            await (_db.update(_db.categories)
                  ..where((c) => c.id.equals(cat.id)))
                .write(CategoriesCompanion(
                  remoteId:   Value(remote.id),
                  syncStatus: const Value('synced'),
                ));
        }
      } catch (e) {
        debugPrint('[Sync] category id=${cat.id} 同步失败: $e');
      }
    }
  }

  Future<void> _syncTransactions() async {
    final pending = await _db.transactionDao.getPendingSync();
    for (final txn in pending) {
      try {
        final accountRow = await (_db.select(_db.accounts)
            ..where((a) => a.id.equals(txn.accountId)))
          .getSingleOrNull();
        if (accountRow?.remoteId == null) continue;

        final data = <String, dynamic>{
          'type': txn.type,
          'amount': txn.amount,
          'currency_code': txn.currencyCode,
          'account_id':       accountRow!.remoteId,
          'category_id':      await _resolveRemoteCategoryId(txn.categoryId),
          'group_id':         await _resolveRemoteGroupId(txn.groupId),
          'transaction_date': txn.transactionDate.toDouble(),
          'is_private':       txn.isPrivate,
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

  Future<int> _resolveRemoteCategoryId(int localId) async {
    final row = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(localId)))
        .getSingleOrNull();
    // 系统分类 remoteId 就是服务端真实 ID（在 fullPull 时写入）
    // 自定义分类如果还没同步，fallback 到「其他」的 remoteId
    if (row?.remoteId != null) return row!.remoteId!;
    // fallback：查服务端「其他」分类
    final other = await (_db.select(_db.categories)
          ..where((c) => c.name.equals('其他') & c.isSystem.equals(true)))
        .getSingleOrNull();
    return other?.remoteId ?? 1;
  }

  Future<int> _resolveRemoteGroupId(int localId) async {
    final row = await (_db.select(_db.groups)
          ..where((g) => g.id.equals(localId)))
        .getSingleOrNull();
    return row?.remoteId ?? localId;
  }
}