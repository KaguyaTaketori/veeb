// lib/providers/permission_provider.dart
//
// 变更说明（Step 8）：
//   - 删除已废弃的旧版 WS 事件分支：new_bill / bill_updated / bill_deleted
//   - 这三个事件是 Bill 时代的遗留，服务端已不再推送

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/ws_service.dart';
import 'transactions_provider.dart';

// ── 权限 Provider ─────────────────────────────────────────────────────────

final permissionsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.permissions ?? [];
});

final hasPermissionProvider = Provider.family<bool, String>((ref, perm) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  if (user.role == 'admin') return true;
  return user.permissions.contains(perm);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.role == 'admin';
});

// ── WS 生命周期管理 Provider ──────────────────────────────────────────────

class _WsLifecycleNotifier extends Notifier<void> {
  StreamSubscription<WsEvent>? _eventSub;
  StreamSubscription<WsStatus>? _statusSub;

  @override
  void build() {
    final authState = ref.watch(authProvider);
    _onAuthChanged(authState);
    ref.onDispose(_dispose);
  }

  void _onAuthChanged(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      _connect();
    } else {
      _disconnect();
    }
  }

  void _connect() {
    _ensureEventSubscription();
    WsService.instance.connect();
  }

  void _disconnect() {
    WsService.instance.disconnect();
  }

  void _ensureEventSubscription() {
    if (_eventSub != null) return;

    _eventSub = WsService.instance.eventStream.listen(
      _onEvent,
      onError: (e) => debugPrint('[WS] eventStream error: $e'),
    );
    debugPrint('[WS] eventStream 订阅已建立');
  }

  void _onEvent(WsEvent event) {
    switch (event.type) {
      case 'new_transaction':
        ref.read(transactionsProvider.notifier).insertFromWs(event.data);

      case 'transaction_updated':
        ref.read(transactionsProvider.notifier).updateFromWs(event.data);

      case 'transaction_deleted':
        final id = event.data['id'] as int?;
        if (id != null) {
          ref.read(transactionsProvider.notifier).removeById(id);
        }

      // ✅ 已删除旧版 Bill 事件分支：
      //   case 'new_bill'      → 服务端已不推送，删除
      //   case 'bill_updated'  → 服务端已不推送，删除
      //   case 'bill_deleted'  → 服务端已不推送，删除

      case 'permissions_updated':
        ref.read(authProvider.notifier).refreshProfile();

      case 'system_notice':
        debugPrint('[系统通知] ${event.data['message']}');
    }
  }

  void _dispose() {
    _eventSub?.cancel();
    _eventSub = null;
    _statusSub?.cancel();
    _statusSub = null;
    debugPrint('[WS] eventStream 订阅已取消');
  }
}

final wsLifecycleProvider = NotifierProvider<_WsLifecycleNotifier, void>(
  _WsLifecycleNotifier.new,
);

/// 向后兼容别名
final wsListenerProvider = wsLifecycleProvider;
