// lib/services/ws_service.dart  （完整替换）
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/auth_event.dart';

enum WsStatus { disconnected, connecting, connected }

class WsEvent {
  final String type;
  final Map<String, dynamic> data;
  final int ts;
  const WsEvent({required this.type, required this.data, required this.ts});

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
        type: json['type'] as String? ?? '',
        data: json['data'] as Map<String, dynamic>? ?? {},
        ts:   json['ts']   as int?    ?? 0,
      );
}

class WsService {
  WsService._();
  static final WsService instance = WsService._();

  static String get _wsBase {
    final base = AppConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return base.endsWith('/v1') ? '$base/ws' : '$base/v1/ws';
  }

  WebSocketChannel?            _channel;
  StreamSubscription<dynamic>? _sub;
  Timer?                       _reconnectTimer;
  Timer?                       _pingTimer;

  final _statusCtrl = StreamController<WsStatus>.broadcast();
  final _eventCtrl  = StreamController<WsEvent>.broadcast();

  Stream<WsStatus> get statusStream => _statusCtrl.stream;
  Stream<WsEvent>  get eventStream  => _eventCtrl.stream;

  WsStatus _status = WsStatus.disconnected;
  WsStatus get status => _status;
  bool get isConnected => _status == WsStatus.connected;

  int _retryCount = 0;
  static const _maxRetry     = 8;
  static const _baseDelay    = Duration(seconds: 2);
  static const _pingInterval = Duration(seconds: 25);

  // ── 连接 ──────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_status == WsStatus.connecting || _status == WsStatus.connected) return;
    _setStatus(WsStatus.connecting);

    final token = await AuthService.instance.getAccessToken();
    if (token == null) {
      _setStatus(WsStatus.disconnected);
      return;
    }

    final uri = Uri.parse('$_wsBase?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
    } catch (e) {
      debugPrint('[WS] 连接失败: $e');
      _setStatus(WsStatus.disconnected);
      _scheduleReconnect();
      return;
    }

    _sub = _channel!.stream.listen(
      _onMessage,
      onDone:  _onDone,
      onError: _onError,
      cancelOnError: false,
    );

    _startPing();
    debugPrint('[WS] 连接建立: $uri');
  }

  void disconnect() {
    _cancelReconnect();
    _cancelPing();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _retryCount = 0;
    _setStatus(WsStatus.disconnected);
  }

  // ── 消息处理 ──────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = msg['type'] as String? ?? '';
    switch (type) {
      case 'auth_ok':
        _setStatus(WsStatus.connected);
        _retryCount = 0;
        debugPrint('[WS] 鉴权成功，user_id=${msg['user_id']}');

      case 'auth_fail':
        debugPrint('[WS] 鉴权失败: ${msg['reason']}');
        // token 过期等原因，断开后不自动重连（等 token 刷新后重新触发）
        disconnect();

      case 'ping':
        _send({'type': 'pong'});

      case 'pong':
        // 心跳回应，无需处理

      case 'force_logout':
        final reason = msg['reason'] as String?;
        debugPrint('[WS] 收到 force_logout，reason=$reason');

        if (reason != null && reason.isNotEmpty) {
          // ✅ 服务端主动封禁/踢出，需要登出 App
          debugPrint('[WS] 服务端强制登出: $reason');
          disconnect();
          AuthEventBus.instance.logout();
        } else {
          // ✅ reason 为 null：WS 连接异常（旧连接被踢/服务端重启），
          //    不登出用户，走正常重连流程
          debugPrint('[WS] WS 连接异常，自动重连中...');
          _cancelPing();
          _sub?.cancel();
          _channel?.sink.close();
          _channel = null;
          _setStatus(WsStatus.disconnected);
          _scheduleReconnect();
        }

      default:
        // 业务事件：new_bill / bill_updated / bill_deleted /
        //           permissions_updated / system_notice 等
        _eventCtrl.add(WsEvent.fromJson(msg));
    }
  }

  void _onDone() {
    debugPrint('[WS] 连接关闭');
    _setStatus(WsStatus.disconnected);
    _cancelPing();
    _scheduleReconnect();
  }

  void _onError(Object error) {
    debugPrint('[WS] 错误: $error');
    _setStatus(WsStatus.disconnected);
    _cancelPing();
    _scheduleReconnect();
  }

  // ── 重连 ──────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    _cancelReconnect();
    if (_retryCount >= _maxRetry) {
      debugPrint('[WS] 达到最大重试次数，停止重连');
      return;
    }
    final delay = _baseDelay * (1 << _retryCount.clamp(0, 5));
    _retryCount++;
    debugPrint('[WS] ${delay.inSeconds}s 后重连 (第 $_retryCount 次)');
    _reconnectTimer = Timer(delay, connect);
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ── 心跳 ──────────────────────────────────────────────────────────────

  void _startPing() {
    _cancelPing();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (isConnected) _send({'type': 'ping'});
    });
  }

  void _cancelPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // ── 工具 ──────────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  void _setStatus(WsStatus s) {
    _status = s;
    _statusCtrl.add(s);
  }

  void dispose() {
    disconnect();
    _statusCtrl.close();
    _eventCtrl.close();
  }
}