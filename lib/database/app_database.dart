// lib/database/app_database.dart
//
// Drift 数据库主类，包含：
//   - 所有表的注册
//   - 版本迁移逻辑（schemaVersion = 7，对应云端 v007）
//   - 系统预设分类的初始化

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/transaction_dao.dart';
import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/group_dao.dart';
import 'daos/scheduled_bill_dao.dart';
import 'daos/statement_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalUsers,
    Groups,
    Categories,
    Accounts,
    Transactions,
    TransactionItems,
    Receipts,
    Statements,
    ScheduledBills,
  ],
  daos: [
    TransactionDao,
    AccountDao,
    CategoryDao,
    GroupDao,
    ScheduledBillDao,
    StatementDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// schemaVersion 必须与云端当前最高迁移版本号一致
  /// 云端 v007 → 本地 schemaVersion = 7
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // 首次安装：建所有表
          await m.createAll();
          // 写入系统预设分类
          await _seedSystemCategories();
        },
        onUpgrade: (m, from, to) async {
          // 从旧版本升级时的增量迁移
          // 注意：每个 if 块必须是幂等的

          if (from < 2) {
            // v002: 暂无本地表改动（云端 v002 是 bills_bot，本地不需要）
          }

          if (from < 3) {
            // v003: 暂无本地表改动（云端 v003 是 app_users）
          }

          if (from < 4) {
            // v004: 暂无本地表改动（云端 v004 是 app_bills）
          }

          if (from < 5) {
            // v005: 暂无本地表改动（云端 v005 是统一 schema 迁移）
          }

          if (from < 6) {
            // v006: 对应云端 v006 admin_permissions
            // LocalUsers 新增 role / permissions / tier
            await m.addColumn(localUsers, localUsers.role);
            await m.addColumn(localUsers, localUsers.permissions);
            await m.addColumn(localUsers, localUsers.tier);
          }

          if (from < 7) {
            // v007: 对应云端 v007 new_accounting_schema
            // 新增所有表
            await m.createTable(groups);
            await m.createTable(categories);
            await m.createTable(accounts);
            await m.createTable(transactions);
            await m.createTable(transactionItems);
            await m.createTable(receipts);
            await m.createTable(statements);
            await m.createTable(scheduledBills);
            // 写入系统预设分类
            await _seedSystemCategories();
          }
        },
        beforeOpen: (details) async {
          // 开启外键约束（SQLite 默认关闭）
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL 模式，读写并发性能更好
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  // ── 系统预设分类初始化 ──────────────────────────────────────────────────

  Future<void> _seedSystemCategories() async {
    final existing = await (select(categories)
          ..where((c) => c.isSystem.equals(true)))
        .get();
    if (existing.isNotEmpty) return; // 已初始化，跳过

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final presets = [
      (name: '餐饮',  icon: '🍜', color: '#E85D30', type: 'expense', order: 1),
      (name: '交通',  icon: '🚇', color: '#3B8BD4', type: 'expense', order: 2),
      (name: '购物',  icon: '🛍️', color: '#1D9E75', type: 'expense', order: 3),
      (name: '娱乐',  icon: '🎮', color: '#EF9F27', type: 'expense', order: 4),
      (name: '医疗',  icon: '💊', color: '#9B59B6', type: 'expense', order: 5),
      (name: '住房',  icon: '🏠', color: '#E74C3C', type: 'expense', order: 6),
      (name: '水电煤', icon: '💡', color: '#2ECC71', type: 'expense', order: 7),
      (name: '工资',  icon: '💰', color: '#1ABC9C', type: 'income',  order: 8),
      (name: '其他',  icon: '📦', color: '#95A5A6', type: 'expense', order: 99),
    ];

    await batch((b) {
      b.insertAll(
        categories,
        presets.map(
          (p) => CategoriesCompanion.insert(
            name:      p.name,
            icon:      Value(p.icon),
            color:     Value(p.color),
            type:      Value(p.type),
            isSystem:  Value(true),
            sortOrder: Value(p.order),
          ),
        ),
      );
    });
  }

  // ── 便捷查询 ────────────────────────────────────────────────────────────

  /// 待同步的记录数（用于 UI 显示同步状态角标）
  Future<int> getPendingSyncCount() async {
    final txnCount = await (selectOnly(transactions)
          ..addColumns([transactions.id.count()])
          ..where(transactions.syncStatus.isNotValue('synced') &
              transactions.syncStatus.isNotNull()))
        .map((r) => r.read(transactions.id.count())!)
        .getSingle();

    final receiptCount = await (selectOnly(receipts)
          ..addColumns([receipts.id.count()])
          ..where(receipts.syncStatus.isNotValue('synced')))
        .map((r) => r.read(receipts.id.count())!)
        .getSingle();

    return txnCount + receiptCount;
  }

  /// 清空所有本地数据（退出登录时调用）
  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(transactionItems).go();
      await delete(receipts).go();
      await delete(transactions).go();
      await delete(scheduledBills).go();
      await delete(statements).go();
      await delete(accounts).go();
      // 保留系统分类，只删自定义分类
      await (delete(categories)..where((c) => c.isSystem.equals(false))).go();
      await delete(groups).go();
      await delete(localUsers).go();
    });
  }

  Future<void> markAllLocalAsPending() async {
    await batch((b) {
      b.update(
        transactions,
        const TransactionsCompanion(syncStatus: Value('pending_create')),
        where: (t) => t.remoteId.isNull() & t.isDeleted.equals(false),
      );
      b.update(
        accounts,
        const AccountsCompanion(syncStatus: Value('pending_create')),
        where: (a) => a.remoteId.isNull() & a.isActive.equals(true),
      );
      b.update(
        categories,
        const CategoriesCompanion(syncStatus: Value('pending_create')),
        where: (c) =>
            c.remoteId.isNull() &
            c.isSystem.equals(false),
      );
    });
  }
}

// ── 数据库连接 ──────────────────────────────────────────────────────────────

QueryExecutor _openConnection() {
  return driftDatabase(name: 'vee_local');
}