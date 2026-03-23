// lib/repositories/transaction_repository.dart — 完整替换（补全缺失方法）

import 'dart:async';
import 'package:drift/drift.dart';
import '../api/transactions_api.dart';
import '../database/app_database.dart';
import '../database/mappers/transaction_mapper.dart'; // ← 使用统一 mapper
import '../models/transaction.dart' as models;
import '../utils/currency.dart';
import '../services/sync/sync_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(transactionsApiProvider),
    coordinator: ref.watch(syncCoordinatorProvider),
    isLoggedIn: ref.watch(authProvider).status == AuthStatus.authenticated,
  );
});

class TransactionRepository {
  final AppDatabase _db;
  final TransactionsApi _api;
  final SyncCoordinator _coordinator;
  final bool _isLoggedIn;

  const TransactionRepository({
    required AppDatabase db,
    required TransactionsApi api,
    required SyncCoordinator coordinator,
    required bool isLoggedIn,
  }) : _db = db,
       _api = api,
       _coordinator = coordinator,
       _isLoggedIn = isLoggedIn;

  /// 创建流水（本地先写，后台同步）
  Future<models.Transaction> create(
    Map<String, dynamic> data,
    int groupId,
  ) async {
    if (_isLoggedIn) {
      return await _api.createTransaction(data);
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final currency = data['currency_code'] as String? ?? 'JPY';
    final amount = (data['amount'] as num).toDouble();

    await _db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        type: Value(data['type'] as String? ?? 'expense'),
        amount: Value(floatToInt(amount, currency)),
        currencyCode: Value(currency),
        baseAmount: Value(floatToInt(amount, currency)),
        exchangeRate: Value(rateToInt(1.0)),
        accountId: data['account_id'] as int,
        categoryId: data['category_id'] as int,
        userId: 0,
        groupId: groupId,
        isPrivate: Value(data['is_private'] as bool? ?? false),
        note: Value(data['note'] as String?),
        payee: Value(data['payee'] as String?),
        transactionDate: ((data['transaction_date'] as num).toDouble()).toInt(),
        createdAt: now,
        updatedAt: now,
        syncStatus: const Value('pending_create'),
      ),
    );
    _coordinator.trySync();
    // Guest 模式返回临时模型
    throw UnimplementedError('Guest mode does not return created model');
  }

  /// 软删除
  Future<void> delete(int id) async {
    if (_isLoggedIn) {
      await _api.deleteTransaction(id);
    } else {
      await _db.transactionDao.softDelete(id);
      _coordinator.trySync();
    }
  }

  /// 按月查询流水流
  Stream<List<models.Transaction>> watchByMonth(
    int groupId,
    int year,
    int month,
  ) {
    return _db.transactionDao.watchByMonth(groupId, year, month).asyncMap((
      rows,
    ) async {
      final cats = await _db.categoryDao.getAvailable(groupId);
      final catMap = {for (final c in cats) c.id: c};
      return rows.map((r) => driftRowToTransaction(r, catMap: catMap)).toList();
    });
  }
}
