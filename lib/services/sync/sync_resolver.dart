import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';

class SyncResolver {
  final AppDatabase _db;

  SyncResolver(this._db);

  factory SyncResolver.fromRef(Ref ref) =>
      SyncResolver(ref.read(appDatabaseProvider));

  Future<int?> groupRemoteId(int localId) async {
    final row = await (_db.select(
      _db.groups,
    )..where((g) => g.id.equals(localId))).getSingleOrNull();
    return row?.remoteId;
  }

  Future<int?> accountRemoteId(int localId) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(localId))).getSingleOrNull();
    return row?.remoteId;
  }

  Future<int?> categoryRemoteId(int localId) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(localId))).getSingleOrNull();
    if (row?.remoteId != null) return row!.remoteId;

    final fallback =
        await (_db.select(_db.categories)
              ..where((c) =>
                  c.name.equals('其他') & c.isSystem.equals(true)))
            .getSingleOrNull();
    return fallback?.remoteId;
  }
}
