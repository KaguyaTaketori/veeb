// lib/database/tables.dart
//
// 本地 Drift 表定义，与云端 schema 保持一致。
// schemaVersion = 7，对应云端 v007 迁移。
//
// 命名规范：
//   - 本地自增主键：id (local)
//   - 云端主键缓存：remote_id (nullable，同步后写入)
//   - 同步状态：sync_status ('synced'|'pending_create'|'pending_update'|'pending_delete')

import 'package:drift/drift.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 枚举（通过 TextColumn 存储，避免 Drift 枚举的迁移复杂性）
// ─────────────────────────────────────────────────────────────────────────────
// UserTier:         free / premium / family_member
// AccountType:      cash / bank / credit_card
// TransactionType:  income / expense / transfer
// CategoryType:     income / expense / both
// RecurringFrequency: daily / weekly / monthly / yearly
// SyncStatus:       synced / pending_create / pending_update / pending_delete

// ─────────────────────────────────────────────────────────────────────────────
// Users（本地缓存登录用户信息，不做离线写入，只读）
// ─────────────────────────────────────────────────────────────────────────────

class LocalUsers extends Table {
  @override
  String get tableName => 'local_users';

  IntColumn  get id              => integer().autoIncrement()();
  IntColumn  get remoteId        => integer().unique()();        // 云端 users.id
  TextColumn get email           => text().nullable()();
  TextColumn get appUsername     => text().nullable()();
  TextColumn get displayName     => text().nullable()();
  TextColumn get avatarUrl       => text().nullable()();
  IntColumn  get tgUserId        => integer().nullable()();
  BoolColumn get isActive        => boolean().withDefault(const Constant(true))();
  TextColumn get role            => text().withDefault(const Constant('user'))();
  TextColumn get permissions     => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get tier            => text().withDefault(const Constant('free'))();
  IntColumn  get aiQuotaMonthly  => integer().withDefault(const Constant(100))();
  IntColumn  get aiQuotaUsed     => integer().withDefault(const Constant(0))();
  IntColumn  get aiQuotaResetAt  => integer().withDefault(const Constant(0))();
  IntColumn  get groupId         => integer().nullable()();      // 关联本地 groups.remote_id
  IntColumn  get createdAt       => integer()();
  IntColumn  get updatedAt       => integer()();
}

// ─────────────────────────────────────────────────────────────────────────────
// Groups（账本/家庭）
// ─────────────────────────────────────────────────────────────────────────────

class Groups extends Table {
  IntColumn  get id            => integer().autoIncrement()();
  IntColumn  get remoteId      => integer().nullable()();
  TextColumn get name          => text().withDefault(const Constant('我的账本'))();
  IntColumn  get ownerId       => integer()();                  // 云端 users.id
  TextColumn get inviteCode    => text().withDefault(const Constant(''))();
  TextColumn get baseCurrency  => text().withDefault(const Constant('JPY'))();
  BoolColumn get isActive      => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus    => text().withDefault(const Constant('synced'))();
  IntColumn  get createdAt     => integer()();
  IntColumn  get updatedAt     => integer()();
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories（分类，含系统预设和自定义）
// ─────────────────────────────────────────────────────────────────────────────

class Categories extends Table {
  IntColumn  get id          => integer().autoIncrement()();
  IntColumn  get remoteId    => integer().nullable()();
  TextColumn get name        => text()();
  TextColumn get icon        => text().nullable()();          // emoji
  TextColumn get color       => text().nullable()();          // hex 颜色
  TextColumn get type        => text().withDefault(const Constant('expense'))();
  BoolColumn get isSystem    => boolean().withDefault(const Constant(false))();
  IntColumn  get groupId     => integer().nullable()();       // null = 全局系统分类
  IntColumn  get sortOrder   => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus  => text().withDefault(const Constant('synced'))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Accounts（资金账户）
// ─────────────────────────────────────────────────────────────────────────────

class Accounts extends Table {
  IntColumn  get id                 => integer().autoIncrement()();
  IntColumn  get remoteId           => integer().nullable()();
  TextColumn get name               => text()();
  TextColumn get type               => text().withDefault(const Constant('cash'))();
  TextColumn get currencyCode       => text().withDefault(const Constant('JPY'))();
  IntColumn  get groupId            => integer().references(Groups, #id)();
  IntColumn  get balanceCache       => integer().withDefault(const Constant(0))();
  IntColumn  get balanceUpdatedAt   => integer().nullable()();
  BoolColumn get isActive           => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus         => text().withDefault(const Constant('synced'))();
  IntColumn  get createdAt          => integer()();
  IntColumn  get updatedAt          => integer()();
}

// ─────────────────────────────────────────────────────────────────────────────
// Transactions（流水主表）
// ─────────────────────────────────────────────────────────────────────────────

class Transactions extends Table {
  IntColumn  get id               => integer().autoIncrement()();
  IntColumn  get remoteId         => integer().nullable()();
  TextColumn get type             => text().withDefault(const Constant('expense'))();

  // 金额（整数，最小单位）
  IntColumn  get amount           => integer().withDefault(const Constant(0))();
  TextColumn get currencyCode     => text().withDefault(const Constant('JPY'))();
  IntColumn  get baseAmount       => integer().withDefault(const Constant(0))();
  // 汇率 * 1_000_000，避免 float 精度损失
  // 例：1 USD = 150 JPY → exchange_rate = 150_000_000
  IntColumn  get exchangeRate     => integer().withDefault(const Constant(1000000))();

  // 关联
  IntColumn  get accountId        => integer().references(Accounts, #id)();
  IntColumn  get toAccountId      => integer().nullable()();    // 转账目标账户
  IntColumn  get transferPeerId   => integer().nullable()();    // 转账对方那条记录
  IntColumn  get categoryId       => integer().references(Categories, #id)();
  IntColumn  get userId           => integer()();               // 云端 users.id
  IntColumn  get groupId          => integer().references(Groups, #id)();

  // 业务
  BoolColumn get isPrivate        => boolean().withDefault(const Constant(false))();
  TextColumn get note             => text().nullable()();
  IntColumn  get transactionDate  => integer()();               // unix timestamp

  // 同步
  TextColumn get syncStatus       => text().withDefault(const Constant('synced'))();
  IntColumn  get createdAt        => integer()();
  IntColumn  get updatedAt        => integer()();
  BoolColumn get isDeleted        => boolean().withDefault(const Constant(false))();

  // 迁移追溯
  IntColumn  get legacyBillId     => integer().nullable()();
}

// ─────────────────────────────────────────────────────────────────────────────
// TransactionItems（流水明细）
// ─────────────────────────────────────────────────────────────────────────────

class TransactionItems extends Table {
  IntColumn  get id             => integer().autoIncrement()();
  IntColumn  get remoteId       => integer().nullable()();
  IntColumn  get transactionId  => integer().references(Transactions, #id)();
  TextColumn get name           => text()();
  TextColumn get nameRaw        => text().withDefault(const Constant(''))();
  RealColumn get quantity       => real().withDefault(const Constant(1.0))();
  IntColumn  get unitPrice      => integer().nullable()();
  IntColumn  get amount         => integer()();
  TextColumn get itemType       => text().withDefault(const Constant('item'))();
  IntColumn  get sortOrder      => integer().withDefault(const Constant(0))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Receipts（凭证图片）
// ─────────────────────────────────────────────────────────────────────────────

class Receipts extends Table {
  IntColumn  get id             => integer().autoIncrement()();
  IntColumn  get remoteId       => integer().nullable()();
  IntColumn  get transactionId  => integer().references(Transactions, #id)();
  TextColumn get imageUrl       => text()();
  TextColumn get localPath      => text().nullable()();   // 本地缓存路径（离线拍摄时使用）
  TextColumn get extractedText  => text().nullable()();
  TextColumn get syncStatus     => text().withDefault(const Constant('synced'))();
  IntColumn  get createdAt      => integer()();
  IntColumn  get updatedAt      => integer()();
  BoolColumn get isDeleted      => boolean().withDefault(const Constant(false))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Statements（信用卡对账单）
// ─────────────────────────────────────────────────────────────────────────────

class Statements extends Table {
  IntColumn  get id                  => integer().autoIncrement()();
  IntColumn  get remoteId            => integer().nullable()();
  IntColumn  get accountId           => integer().references(Accounts, #id)();
  TextColumn get periodStart         => text()();             // YYYY-MM-DD
  TextColumn get periodEnd           => text()();
  IntColumn  get totalAmount         => integer().withDefault(const Constant(0))();
  BoolColumn get isAmountConfirmed   => boolean().withDefault(const Constant(false))();
  TextColumn get closingDate         => text()();
  TextColumn get dueDate             => text()();
  BoolColumn get isSettled           => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus          => text().withDefault(const Constant('synced'))();
  IntColumn  get createdAt           => integer()();
  IntColumn  get updatedAt           => integer()();
}

// ─────────────────────────────────────────────────────────────────────────────
// ScheduledBills（周期性账单）
// ─────────────────────────────────────────────────────────────────────────────

class ScheduledBills extends Table {
  IntColumn  get id             => integer().autoIncrement()();
  IntColumn  get remoteId       => integer().nullable()();
  TextColumn get title          => text().withDefault(const Constant('未命名订阅'))();
  IntColumn  get amount         => integer()();
  TextColumn get currencyCode   => text().withDefault(const Constant('JPY'))();
  IntColumn  get accountId      => integer().references(Accounts, #id)();
  IntColumn  get categoryId     => integer().references(Categories, #id)();
  IntColumn  get userId         => integer()();
  IntColumn  get groupId        => integer().references(Groups, #id)();
  TextColumn get frequency      => text().withDefault(const Constant('monthly'))();
  TextColumn get nextDueDate    => text()();                  // YYYY-MM-DD
  BoolColumn get autoRecord     => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive       => boolean().withDefault(const Constant(true))();
  IntColumn  get lastExecutedAt => integer().nullable()();
  TextColumn get syncStatus     => text().withDefault(const Constant('synced'))();
  IntColumn  get createdAt      => integer()();
  IntColumn  get updatedAt      => integer()();
}