import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
 
part 'scheduled_bill_dao.g.dart';
 
@DriftAccessor(tables: [ScheduledBills])
class ScheduledBillDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduledBillDaoMixin {
  ScheduledBillDao(super.db);
 
  Stream<List<ScheduledBill>> watchActive(int groupId) =>
      (select(scheduledBills)
            ..where((s) =>
                s.groupId.equals(groupId) & s.isActive.equals(true))
            ..orderBy([(s) => OrderingTerm.asc(s.nextDueDate)]))
          .watch();
 
  /// 今日或已过期的待执行账单
  Future<List<ScheduledBill>> getDue() {
    final today =
        DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    return (select(scheduledBills)
          ..where((s) =>
              s.isActive.equals(true) &
              s.autoRecord.equals(true) &
              s.nextDueDate.isSmallerOrEqualValue(today)))
        .get();
  }
 
  Future<int> insertScheduledBill(ScheduledBillsCompanion entry) =>
      into(scheduledBills).insert(
        entry.copyWith(syncStatus: const Value('pending_create')),
      );
 
  Future<void> updateNextDueDate(int id, String nextDueDate) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (update(scheduledBills)..where((s) => s.id.equals(id))).write(
      ScheduledBillsCompanion(
        nextDueDate:    Value(nextDueDate),
        lastExecutedAt: Value(now),
        syncStatus:     const Value('pending_update'),
      ),
    );
  }
}