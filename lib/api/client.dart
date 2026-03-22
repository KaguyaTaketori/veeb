// lib/api/client.dart  （完整替换）
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(dio));
  if (AppConfig.isDebug) dio.interceptors.add(_logInterceptor());

  return dio;
});

final authClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_logInterceptor());
});

// ── 拦截器内部标记 key ────────────────────────────────────────────────────
const _kRetried = '_auth_retried';

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  Completer<String?>? _refreshCompleter;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthService.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 非 401 直接透传
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // auth 相关路径不重试，防止死循环
    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
      handler.next(err);
      return;
    }

    // ✅ 关键修复：已经重试过的请求不再重试
    // 当 _retry() 用相同的 _dio 发出请求时，该请求携带此标记，
    // 拦截器检测到后直接透传错误，而不是再次刷新 token，
    // 从而彻底打破：getMe → 401 → refresh → retry → 401 → refresh ... 无限循环
    if (err.requestOptions.extra[_kRetried] == true) {
      debugPrint('[Auth] 重试请求仍返回 401，放弃重试，清除 token');
      await AuthService.instance.clearTokens();
      handler.next(err);
      return;
    }

    // 已有正在进行的刷新，等待其结果
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken == null) {
        handler.next(err);
        return;
      }
      handler.resolve(await _retry(err.requestOptions, newToken));
      return;
    }

    // 发起新的 token 刷新
    _refreshCompleter = Completer<String?>();
    try {
      final newToken = await _doRefresh();
      _refreshCompleter!.complete(newToken);

      if (newToken == null) {
        handler.next(err);
        return;
      }
      handler.resolve(await _retry(err.requestOptions, newToken));
    } catch (_) {
      _refreshCompleter!.complete(null);
      handler.next(err);
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await AuthService.instance.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      // 使用无拦截器的独立 Dio，避免刷新请求本身也被拦截
      final resp = await Dio(BaseOptions(baseUrl: AppConfig.baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data    = resp.data as Map<String, dynamic>;
      final newAccess  = data['access_token']  as String;
      final newRefresh = data['refresh_token'] as String;
      await AuthService.instance.saveTokens(
        accessToken:  newAccess,
        refreshToken: newRefresh,
      );
      debugPrint('[Auth] Token 刷新成功');
      return newAccess;
    } catch (e) {
      debugPrint('[Auth] Token 刷新失败: $e，清除本地 token');
      await AuthService.instance.clearTokens();
      return null;
    }
  }

  /// 重试请求时写入 _kRetried 标记，
  /// 防止该请求再次触发 onError 中的刷新逻辑
  Future<Response> _retry(RequestOptions options, String newToken) {
    return _dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method:  options.method,
        headers: {
          ...options.headers,
          'Authorization': 'Bearer $newToken',
        },
        extra: {
          ...options.extra,
          _kRetried: true,   // ← 打标记，拦截器看到后不再重试
        },
      ),
    );
  }
}

LogInterceptor _logInterceptor() => LogInterceptor(
      requestBody:  true,
      responseBody: true,
      logPrint: (o) => debugPrint('[Dio] $o'),
    );