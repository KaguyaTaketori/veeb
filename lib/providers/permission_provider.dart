// lib/providers/permission_provider.dart  （完整替换）
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/ws_service.dart';
import '../providers/bills_provider.dart';

// ── 权限 Provider ─────────────────────────────────────────────────────────

final permissionsProvider = Provider<List<String>>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.permissions ?? [];
});

final hasPermissionProvider = Provider.family<bool, String>((ref, perm) {
  final user = ref.watch(authProvider).user;
  if (user == null) return false;
  if (user.role == 'admin') return true;   // 管理员拥有全部权限
  return user.permissions.contains(perm);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user?.role == 'admin';
});

// ── WS 生命周期管理 Provider ──────────────────────────────────────────────
//
// 修复点：之前用 Provider<void> 每次 rebuild 都创建新订阅，旧订阅不取消，
// 导致 eventStream 有 N 个订阅，refreshProfile 被调用 N 次。
//
// 修复方案：改用 StreamProvider 监听 authProvider 状态变化，
// WS 连接逻辑放在单独的 _WsLifecycleNotifier 中，
// 确保订阅唯一且在 Notifier 销毁时正确取消。

class _WsLifecycleNotifier extends Notifier<void> {
  StreamSubscription<WsEvent>? _eventSub;
  StreamSubscription<WsStatus>? _statusSub;

  @override
  void build() {
    // 监听 auth 状态变化
    final authState = ref.watch(authProvider);
    _onAuthChanged(authState);

    // Provider 销毁时清理所有订阅
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
    // 先确保订阅只建立一次
    _ensureEventSubscription();
    WsService.instance.connect();
  }

  void _disconnect() {
    WsService.instance.disconnect();
  }

  void _ensureEventSubscription() {
    if (_eventSub != null) return;   // ← 避免重复订阅

    _eventSub = WsService.instance.eventStream.listen(
      _onEvent,
      onError: (e) => debugPrint('[WS] eventStream error: $e'),
    );
    debugPrint('[WS] eventStream 订阅已建立');
  }

  void _onEvent(WsEvent event) {
    switch (event.type) {
      case 'new_bill':
        ref.read(billsProvider.notifier).insertBillFromWs(event.data);

      case 'bill_updated':
        ref.read(billsProvider.notifier).updateBillFromWs(event.data);

      case 'bill_deleted':
        final id = event.data['id'] as int?;
        if (id != null) ref.read(billsProvider.notifier).removeBillById(id);

      case 'permissions_updated':
        // 权限变更：刷新用户信息（只调用一次）
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

/// 在 AuthGate 中 ref.watch(wsLifecycleProvider) 即可启动 WS 生命周期管理
final wsLifecycleProvider =
    NotifierProvider<_WsLifecycleNotifier, void>(_WsLifecycleNotifier.new);

/// 向后兼容别名（原 wsListenerProvider 的使用方）
final wsListenerProvider = wsLifecycleProvider;