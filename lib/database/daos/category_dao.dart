import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAvailable(int? groupId) =>
      (select(categories)
            ..where((c) =>
                c.isSystem.equals(true) |
                (groupId != null
                    ? c.groupId.equals(groupId)
                    : const Constant(false)))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Stream<List<Category>> watchAvailable(int? groupId) =>
      (select(categories)
            ..where((c) =>
                c.isSystem.equals(true) |
                (groupId != null
                    ? c.groupId.equals(groupId)
                    : const Constant(false)))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(
        entry.copyWith(syncStatus: const Value('pending_create')),
      );

  Future<List<Category>> getPendingSync() =>
      (select(categories)
            ..where((c) =>
                c.syncStatus.isNotValue('synced') & c.isSystem.equals(false)))
          .get();
}