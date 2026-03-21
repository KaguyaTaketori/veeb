import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../api/transactions_api.dart';
import '../../../models/category.dart';
import '../../../exceptions/app_exception.dart';
import '../../../providers/database_provider.dart';
import '../syncer_interface.dart';

class CategorySyncer implements EntitySyncer {
  final Ref _ref;
  CategorySyncer(this._ref);

  AppDatabase      get _db          => _ref.read(appDatabaseProvider);
  CategoriesApi    get _categoryApi => _ref.read(categoriesApiProvider);

  @override
  Future<void> pushPending() async {
    final pending = await _db.categoryDao.getPendingSync();

    for (final cat in pending) {
      if (cat.isSystem) continue;
      try {
        switch (cat.syncStatus) {
          case 'pending_create':
            await _pushCreate(cat);
          case 'pending_update':
            await _pushUpdate(cat);
          case 'pending_delete':
            await _pushDelete(cat);
        }
      } catch (e) {
        debugPrint('[CategorySyncer] id=${cat.id} 失败: $e');
      }
    }
  }

  Future<void> _pushCreate(Category cat) async {
    final groupRemoteId = await _resolveGroupRemoteId(cat.groupId);
    if (groupRemoteId == null) return; // group 未同步，跳过

    final remote = await _categoryApi.createCategory({
      'name':       cat.name,
      'icon':       cat.icon ?? '📦',
      'color':      cat.color ?? '#95A5A6',
      'type':       cat.type,
      'group_id':   groupRemoteId,
      'sort_order': cat.sortOrder,
    });
    await (_db.update(_db.categories)
          ..where((c) => c.id.equals(cat.id)))
        .write(CategoriesCompanion(
          remoteId:   Value(remote.id),
          syncStatus: const Value('synced'),
        ));
  }

  Future<void> _pushUpdate(Category cat) async {
    if (cat.remoteId == null) return;
    await _categoryApi.patchCategory(
      cat.remoteId!,
      {
        if (cat.icon != null) 'icon': cat.icon,
        if (cat.color != null) 'color': cat.color,
        'name': cat.name,
        'sort_order': cat.sortOrder,
      },
    );
    await (_db.update(_db.categories)
          ..where((c) => c.id.equals(cat.id)))
        .write(const CategoriesCompanion(
          syncStatus: Value('synced'),
        ));
  }

  Future<void> _pushDelete(Category cat) async {
    if (cat.remoteId != null) {
      try {
        await _categoryApi.deleteCategory(cat.remoteId!);
      } catch (e) {
        // 404 说明服务端已删除，继续清本地
        if (e is! AppException || e.statusCode != 404) rethrow;
      }
    }
    await (_db.delete(_db.categories)
          ..where((c) => c.id.equals(cat.id)))
        .go();
  }

  @override
  Future<void> pull({DateTime? since}) async {
    final localGroup = await _db.groupDao.getDefault();
    if (localGroup?.remoteId == null) return;

    final remotes = await _categoryApi.listCategories(
      groupId: localGroup!.remoteId,
    );

    for (final remote in remotes) {
      final local = await (_db.select(_db.categories)
            ..where((c) => c.remoteId.equals(remote.id)))
          .getSingleOrNull();

      if (local != null) {
        // 已存在：更新
        await (_db.update(_db.categories)
              ..where((c) => c.id.equals(local.id)))
            .write(CategoriesCompanion(
              name:      Value(remote.name),
              icon:      Value(remote.icon),
              color:     Value(remote.color),
              syncStatus: const Value('synced'),
            ));
      } else {
        // 不存在：按名称匹配（防止系统分类重复插入）
        final byName = await (_db.select(_db.categories)
              ..where((c) =>
                  c.name.equals(remote.name) & c.remoteId.isNull()))
            .getSingleOrNull();

        if (byName != null) {
          await (_db.update(_db.categories)
                ..where((c) => c.id.equals(byName.id)))
              .write(CategoriesCompanion(
                remoteId:   Value(remote.id),
                syncStatus: const Value('synced'),
              ));
        } else {
          await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              remoteId:   Value(remote.id),
              name:       remote.name,
              icon:       Value(remote.icon),
              color:      Value(remote.color),
              type:       Value(remote.type),
              isSystem:   Value(remote.isSystem),
              groupId:    Value(remote.groupId ?? localGroup.id),
              sortOrder:  Value(remote.sortOrder),
              syncStatus: const Value('synced'),
            ),
          );
        }
      }
    }
  }

  Future<int?> _resolveGroupRemoteId(int? localGroupId) async {
    if (localGroupId == null) return null;
    final row = await (_db.select(_db.groups)
          ..where((g) => g.id.equals(localGroupId)))
        .getSingleOrNull();
    return row?.remoteId;
  }
}