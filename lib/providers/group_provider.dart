import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/groups_api.dart';
import '../models/group.dart';
import '../database/app_database.dart' as db;
import 'auth_provider.dart';
import 'database_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'group_provider.freezed.dart';

@freezed
abstract class GroupState with _$GroupState {
  const factory GroupState({
    Group? group,
    @Default(false) bool loading,
    String? error,
  }) = _GroupState;
}

class GroupNotifier extends Notifier<GroupState> {
  @override
  GroupState build() {
    final authStatus = ref.watch(authProvider).status;

    if (authStatus == AuthStatus.authenticated) {
      Future.microtask(load);
    } else {
      Future.microtask(_loadOrCreateLocal);
    }
    return const GroupState(loading: true);
  }

  Future<void> _loadOrCreateLocal() async {
    final database = ref.read(appDatabaseProvider);
    var group = await database.groupDao.getDefault();

    if (group == null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final groupId = await database.groupDao.insertGroup(
        db.GroupsCompanion.insert(
          name: const Value('我的账本'),
          ownerId: 0,
          inviteCode: const Value('local'),
          baseCurrency: const Value('JPY'),
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('synced'),
        ),
      );
      group = await database.groupDao.getById(groupId);

      await database.accountDao.insertAccount(
        db.AccountsCompanion.insert(
          name: '现金',
          type: const Value('cash'),
          currencyCode: const Value('JPY'),
          groupId: groupId,
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('synced'),
        ),
      );
    }

    state = state.copyWith(
      group: group != null ? _driftGroupToModel(group) : null,
      loading: false,
    );
  }

  GroupsApi get _api => ref.read(groupsApiProvider);

  Group _driftGroupToModel(db.Group row) {
    return Group(
      id: row.id,
      name: row.name,
      ownerId: row.ownerId,
      inviteCode: row.inviteCode,
      baseCurrency: row.baseCurrency,
      isActive: row.isActive,
      createdAt: row.createdAt.toDouble(),
      updatedAt: row.updatedAt.toDouble(),
    );
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final group = await _api.getMyGroup();
      state = state.copyWith(group: group, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> createDefault() async {
    final isLoggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (isLoggedIn) {
      state = state.copyWith(loading: true, error: null);
      try {
        final group = await _api.createGroup({
          'name': '我的账本',
          'base_currency': 'JPY',
        });
        state = state.copyWith(group: group, loading: false);
      } catch (e) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    } else {
      await _loadOrCreateLocal(); // 复用本地创建逻辑
    }
  }

  Future<void> join(String inviteCode) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final group = await _api.joinGroup(inviteCode);
      state = state.copyWith(group: group, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final groupProvider = NotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);

final currentGroupIdProvider = Provider<int?>((ref) {
  return ref.watch(groupProvider).group?.id;
});
