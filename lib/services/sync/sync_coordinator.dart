import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'syncer_interface.dart';
import 'syncers/category_syncer.dart';
import 'syncers/account_syncer.dart';
import 'syncers/transaction_syncer.dart';
import 'syncers/scheduled_bill_syncer.dart';

enum SyncState { idle, syncing, error }

class SyncCoordinator {
  final List<EntitySyncer> _syncers;
  final _stateCtrl = StreamController<SyncState>.broadcast();

  Stream<SyncState> get stateStream => _stateCtrl.stream;

  bool _isSyncing = false;
  Timer? _debounceTimer;

  SyncCoordinator(Ref ref)
      : _syncers = [
          CategorySyncer(ref),    // 必须第一个，流水依赖它
          AccountSyncer(ref),     // 必须第二个，流水依赖它
          TransactionSyncer(ref), // 第三个
          ScheduledBillSyncer(ref),
        ];

  /// 防抖同步（本地写入后调用）
  void trySync() {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(seconds: 2), syncNow);
  }

  /// 立即同步
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _stateCtrl.add(SyncState.syncing);
    try {
      for (final syncer in _syncers) {
        await syncer.pushPending();
      }
    } catch (e) {
      debugPrint('[Sync] 同步失败: $e');
      _stateCtrl.add(SyncState.error);
    } finally {
      _isSyncing = false;
      _stateCtrl.add(SyncState.idle);
    }
  }

  /// 全量拉取（首次登录）
  Future<void> fullPull(int remoteGroupId) async {
    _stateCtrl.add(SyncState.syncing);
    try {
      for (final syncer in _syncers) {
        await syncer.pull();
      }
    } finally {
      _stateCtrl.add(SyncState.idle);
    }
  }

  /// 增量拉取（后台定期）
  Future<void> incrementalPull(DateTime since) async {
    for (final syncer in _syncers) {
      await syncer.pull(since: since);
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _stateCtrl.close();
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});