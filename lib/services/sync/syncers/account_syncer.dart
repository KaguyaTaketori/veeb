// lib/services/sync/syncers/account_syncer.dart — 完整替换
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../api/groups_api.dart';
import '../../../providers/database_provider.dart';
import '../syncer_interface.dart';
import '../sync_resolver.dart'; // ← 新增

class AccountSyncer implements EntitySyncer {
  final Ref _ref;
  late final SyncResolver _resolver;

  AccountSyncer(this._ref) : _resolver = SyncResolver.fromRef(_ref);

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  AccountsApi get _api => _ref.read(accountsApiProvider);

  @override
  Future<void> pushPending() async {
    final pending = await _db.accountDao.getPendingSync();
    for (final account in pending) {
      try {
        final groupRemoteId = await _resolver.groupRemoteId(account.groupId);
        if (groupRemoteId == null) continue;

        switch (account.syncStatus) {
          case 'pending_create':
            final remote = await _api.createAccount(
              name: account.name,
              type: account.type,
              currencyCode: account.currencyCode,
              groupId: groupRemoteId,
            );
            await _db.accountDao.markSynced(account.id, remote.id);

          case 'pending_update':
            if (account.remoteId == null) continue;
            await _api.patchAccount(account.remoteId!, {
              'name': account.name,
              'is_active': account.isActive,
            });
            await (_db.update(_db.accounts)
                  ..where((a) => a.id.equals(account.id)))
                .write(const AccountsCompanion(syncStatus: Value('synced')));
        }
      } catch (e) {
        debugPrint('[AccountSyncer] id=${account.id} 失败: $e');
      }
    }
  }

  @override
  Future<void> pull({DateTime? since}) async {
    final localGroup = await _db.groupDao.getDefault();
    if (localGroup?.remoteId == null) return;

    final remotes = await _api.listAccounts(groupId: localGroup!.remoteId!);

    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.accounts,
        remotes.map(
          (a) => AccountsCompanion.insert(
            remoteId: Value(a.id),
            name: a.name,
            type: Value(a.type),
            currencyCode: Value(a.currencyCode),
            groupId: localGroup.id,
            balanceCache: Value(a.balanceCache),
            isActive: Value(a.isActive),
            createdAt: a.createdAt.toInt(),
            updatedAt: a.updatedAt.toInt(),
            syncStatus: const Value('synced'),
          ),
        ),
      );
    });
  }
}
