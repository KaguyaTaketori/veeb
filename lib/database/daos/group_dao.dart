import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';
 
part 'group_dao.g.dart';
 
@DriftAccessor(tables: [Groups])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);
 
  Future<Group?> getDefault() =>
      (select(groups)..where((g) => g.isActive.equals(true))..limit(1))
          .getSingleOrNull();
 
  Future<int> insertGroup(GroupsCompanion entry) =>
      into(groups).insert(
        entry.copyWith(syncStatus: const Value('pending_create')),
      );
 
  Future<void> markSynced(int localId, int remoteId) =>
      (update(groups)..where((g) => g.id.equals(localId))).write(
        GroupsCompanion(
          remoteId:   Value(remoteId),
          syncStatus: const Value('synced'),
        ),
      );
}