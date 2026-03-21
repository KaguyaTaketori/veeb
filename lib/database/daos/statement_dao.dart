import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
 
part 'statement_dao.g.dart';
 
@DriftAccessor(tables: [Statements])
class StatementDao extends DatabaseAccessor<AppDatabase>
    with _$StatementDaoMixin {
  StatementDao(super.db);
 
  Stream<List<Statement>> watchByAccount(int accountId) =>
      (select(statements)
            ..where((s) => s.accountId.equals(accountId))
            ..orderBy([(s) => OrderingTerm.desc(s.periodStart)]))
          .watch();
 
  Future<Statement?> getCurrent(int accountId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return (select(statements)
          ..where((s) =>
              s.accountId.equals(accountId) &
              s.periodStart.isSmallerOrEqualValue(today) &
              s.periodEnd.isBiggerOrEqualValue(today))
          ..limit(1))
        .getSingleOrNull();
  }
 
  Future<int> insertStatement(StatementsCompanion entry) =>
      into(statements).insert(
        entry.copyWith(syncStatus: const Value('pending_create')),
      );
}