import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../api/groups_api.dart';
import '../../../exceptions/app_exception.dart';
import '../../../providers/database_provider.dart';
import '../syncer_interface.dart';

class AccountSyncer implements EntitySyncer {
  final Ref _ref;
  AccountSyncer(this._ref);

  AppDatabase  get _db         => _ref.read(appDatabaseProvider);
  AccountsApi  get _accountApi => _ref.read(accountsApiProvider);

  @override
  Future<void> pushPending() async {
    final pending = await _db.accountDao.getPendingSync();

    for (final account in pending) {
      try {
        final groupRemoteId =
            await _resolveGroupRemoteId(account.groupId);
        if (groupRemoteId == null) continue;

        switch (account.syncStatus) {
          case 'pending_create':
            final remote = await _accountApi.createAccount(
              name:         account.name,
              type:         account.type,
              currencyCode: account.currencyCode,
              groupId:      groupRemoteId,
            );
            await _db.accountDao.markSynced(account.id, remote.id);

          case 'pending_update':
            if (account.remoteId == null) continue;
            await _accountApi.patchAccount(
              account.remoteId!,
              {'name': account.name, 'is_active': account.isActive},
            );
            await (_db.update(_db.accounts)
                  ..where((a) => a.id.equals(account.id)))
                .write(const AccountsCompanion(
                    syncStatus: Value('synced')));
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

    final remotes = await _accountApi.listAccounts(
        groupId: localGroup!.remoteId!);

    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.accounts,
        remotes.map((a) => AccountsCompanion.insert(
          remoteId:     Value(a.id),
          name:         a.name,
          type:         Value(a.type),
          currencyCode: Value(a.currencyCode),
          groupId:      localGroup.id, // 本地 group id
          balanceCache: Value(a.balanceCache),
          isActive:     Value(a.isActive),
          createdAt:    a.createdAt.toInt(),
          updatedAt:    a.updatedAt.toInt(),
          syncStatus:   const Value('synced'),
        )),
      );
    });
  }

  Future<int?> _resolveGroupRemoteId(int localGroupId) async {
    final row = await (_db.select(_db.groups)
          ..where((g) => g.id.equals(localGroupId)))
        .getSingleOrNull();
    return row?.remoteId;
  }
}