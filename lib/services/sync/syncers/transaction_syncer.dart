// lib/services/sync/syncers/transaction_syncer.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:vee_app/services/sync/sync_resolver.dart';

import '../../../database/app_database.dart';
import '../../../api/transactions_api.dart';
import '../../../models/transaction.dart' as models;
import '../../../exceptions/app_exception.dart';
import '../../../providers/database_provider.dart';
import '../syncer_interface.dart';
import '../../../utils/currency.dart';

class TransactionSyncer implements EntitySyncer {
  final Ref _ref;
  late final SyncResolver _resolver;
  TransactionSyncer(this._ref) : _resolver = SyncResolver.fromRef(_ref);

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  TransactionsApi get _txnApi => _ref.read(transactionsApiProvider);

  @override
  Future<void> pushPending() async {
    final pending = await _db.transactionDao.getPendingSync();

    for (final txn in pending) {
      try {
        switch (txn.syncStatus) {
          case 'pending_create':
            await _pushCreate(txn);
          case 'pending_update':
            await _pushUpdate(txn);
          case 'pending_delete':
            await _pushDelete(txn);
        }
      } catch (e) {
        debugPrint('[TransactionSyncer] id=${txn.id} 失败: $e');
      }
    }
  }

  Future<void> _pushCreate(Transaction txn) async {
    // 使用 SyncResolver 替代原三个私有方法
    final accountRemoteId = await _resolver.accountRemoteId(txn.accountId);
    final categoryRemoteId = await _resolver.categoryRemoteId(txn.categoryId);
    final groupRemoteId = await _resolver.groupRemoteId(txn.groupId);

    if (accountRemoteId == null ||
        categoryRemoteId == null ||
        groupRemoteId == null) {
      debugPrint('[TransactionSyncer] 依赖未同步，跳过 id=${txn.id}');
      return;
    }

    // 使用统一货币工具替代内联 toFloat
    final items = await _db.transactionDao.getItems(txn.id);
    final remote = await _txnApi.createTransaction({
      'type': txn.type,
      'amount': intToFloat(txn.amount, txn.currencyCode), // ← 统一函数
      'currency_code': txn.currencyCode,
      'exchange_rate': rateFromInt(txn.exchangeRate), // ← 统一函数
      'account_id': accountRemoteId,
      'category_id': categoryRemoteId,
      'group_id': groupRemoteId,
      'is_private': txn.isPrivate,
      'note': txn.note,
      if (txn.payee != null && txn.payee!.isNotEmpty) 'payee': txn.payee,
      'transaction_date': txn.transactionDate.toDouble(),
      'receipt_url': '', // 图片上传逻辑保持不变
      'items': items
          .map(
            (i) => {
              'name': i.name,
              'name_raw': i.nameRaw,
              'quantity': i.quantity,
              'unit_price': i.unitPrice != null
                  ? intToFloat(i.unitPrice!, txn.currencyCode)
                  : null,
              'amount': intToFloat(i.amount, txn.currencyCode),
              'item_type': i.itemType,
              'sort_order': i.sortOrder,
            },
          )
          .toList(),
    });

    await _db.transactionDao.markSynced(txn.id, remote.id);
  }

  Future<void> _pushUpdate(Transaction txn) async {
    if (txn.remoteId == null) return;
    await _txnApi.patchTransaction(txn.remoteId!, {
      'note': txn.note,
      'is_private': txn.isPrivate,
      'transaction_date': txn.transactionDate.toDouble(),
      if (txn.payee != null) 'payee': txn.payee, // ✅ 新增（null 表示清除）
    });
    await (_db.update(_db.transactions)..where((t) => t.id.equals(txn.id)))
        .write(const TransactionsCompanion(syncStatus: Value('synced')));
  }

  Future<void> _pushDelete(Transaction txn) async {
    if (txn.remoteId != null) {
      try {
        await _txnApi.deleteTransaction(txn.remoteId!);
      } catch (e) {
        if (e is! AppException || e.statusCode != 404) rethrow;
      }
    }
    await (_db.delete(
      _db.transactions,
    )..where((t) => t.id.equals(txn.id))).go();
  }

  @override
  Future<void> pull({DateTime? since}) async {
    final localGroup = await _db.groupDao.getDefault();
    if (localGroup?.remoteId == null) return;

    final now = DateTime.now();

    if (since != null) {
      await _pullMonth(
        localGroup!.remoteId!,
        localGroup.id,
        now.year,
        now.month,
        updatedAfter: since,
      );
    } else {
      for (var i = 0; i < 3; i++) {
        final month = DateTime(now.year, now.month - i);
        await _pullMonth(
          localGroup!.remoteId!,
          localGroup.id,
          month.year,
          month.month,
        );
      }
    }
  }

  Future<void> _pullMonth(
    int remoteGroupId,
    int localGroupId,
    int year,
    int month, {
    DateTime? updatedAfter,
  }) async {
    final data = await _txnApi.listTransactions(
      groupId: remoteGroupId,
      year: year,
      month: month,
      updatedAfter: updatedAfter?.millisecondsSinceEpoch != null
          ? updatedAfter!.millisecondsSinceEpoch / 1000
          : null,
    );

    final transactions = (data['transactions'] as List? ?? [])
        .map((e) => models.Transaction.fromJson(e as Map<String, dynamic>))
        .toList();

    final localAccounts = await (_db.select(
      _db.accounts,
    )..where((a) => a.remoteId.isNotNull())).get();
    final localCategories = await (_db.select(
      _db.categories,
    )..where((c) => c.remoteId.isNotNull())).get();

    final accountMap = {for (final a in localAccounts) a.remoteId!: a.id};
    final categoryMap = {for (final c in localCategories) c.remoteId!: c.id};

    for (final t in transactions) {
      final localAccountId = accountMap[t.accountId];
      final localCategoryId = categoryMap[t.categoryId];
      if (localAccountId == null || localCategoryId == null) continue;

      const noDecimal = {'JPY', 'KRW', 'VND'};
      int toInt(double v, String currency) =>
          noDecimal.contains(currency) ? v.round() : (v * 100).round();

      await _db
          .into(_db.transactions)
          .insertOnConflictUpdate(
            TransactionsCompanion.insert(
              remoteId: Value(t.id),
              type: Value(t.type),
              amount: Value(toInt(t.amount, t.currencyCode)),
              currencyCode: Value(t.currencyCode),
              baseAmount: Value(toInt(t.baseAmount, t.currencyCode)),
              exchangeRate: Value((t.exchangeRate * 1_000_000).toInt()),
              accountId: localAccountId,
              categoryId: localCategoryId,
              userId: t.userId,
              groupId: localGroupId,
              isPrivate: Value(t.isPrivate),
              note: Value(t.note),
              payee: Value(t.payee), // ✅ 新增
              transactionDate: t.transactionDate.toInt(),
              createdAt: t.createdAt.toInt(),
              updatedAt: t.updatedAt.toInt(),
              isDeleted: Value(t.isDeleted),
              syncStatus: const Value('synced'),
            ),
          );
    }
  }

  Future<String> _uploadLocalImage(String localPath) async {
    try {
      final file = File(localPath);
      final bytes = await file.readAsBytes();
      final name = localPath.split('/').last;
      final mime = name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      return await _ref
          .read(transactionsApiProvider)
          .uploadReceipt(fileBytes: bytes, filename: name, mimeType: mime);
    } catch (e) {
      debugPrint('[TransactionSyncer] 图片上传失败: $e');
      return '';
    }
  }
}
