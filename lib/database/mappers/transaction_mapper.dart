import '../app_database.dart';
import '../../models/transaction.dart' as models;
import '../../utils/currency.dart';

/// 将 Drift Transaction 行 + 可选分类映射为领域模型
/// 替代 TransactionsProvider 和 StatsProvider 中各自的同名私有方法
models.Transaction driftRowToTransaction(
  Transaction row, {
  Map<int, Category>? catMap,
}) {
  final cat = catMap?[row.categoryId];

  return models.Transaction(
    id: row.id,
    type: row.type,
    amount: intToFloat(row.amount, row.currencyCode),
    currencyCode: row.currencyCode,
    baseAmount: intToFloat(row.baseAmount, row.currencyCode),
    exchangeRate: rateFromInt(row.exchangeRate),
    accountId: row.accountId,
    toAccountId: row.toAccountId,
    transferPeerId: row.transferPeerId,
    categoryId: row.categoryId,
    userId: row.userId,
    groupId: row.groupId,
    isPrivate: row.isPrivate,
    note: row.note,
    payee: row.payee,
    transactionDate: row.transactionDate.toDouble(),
    createdAt: row.createdAt.toDouble(),
    updatedAt: row.updatedAt.toDouble(),
    isDeleted: row.isDeleted,
    categoryName: cat?.name,
    categoryIcon: cat?.icon,
    categoryColor: cat?.color,
  );
}
