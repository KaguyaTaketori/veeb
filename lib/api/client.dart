// lib/api/client.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../exceptions/app_exception.dart';
import '../services/auth_service.dart';

// ── 无鉴权客户端（注册/登录/刷新专用）──────────────────────────────────

final authClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_logInterceptor());
});

// ── 带鉴权客户端（所有业务接口）────────────────────────────────────────

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

// ── Token 注入 + 401 自动刷新拦截器 ─────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  // 防止并发请求同时触发刷新
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
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // 已经在刷新路径上，直接失败避免死循环
    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
      handler.next(err);
      return;
    }

    // 若已有刷新进行中，等待结果
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken == null) {
        handler.next(err);
        return;
      }
      handler.resolve(await _retry(err.requestOptions, newToken));
      return;
    }

    // 发起刷新
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
      final resp = await Dio(BaseOptions(baseUrl: AppConfig.baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = resp.data as Map<String, dynamic>;
      final newAccess  = data['access_token']  as String;
      final newRefresh = data['refresh_token'] as String;
      await AuthService.instance.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return newAccess;
    } catch (_) {
      // 刷新失败，清除 token，触发登出
      await AuthService.instance.clearTokens();
      return null;
    }
  }

  Future<Response> _retry(RequestOptions options, String newToken) {
    return _dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {...options.headers, 'Authorization': 'Bearer $newToken'},
      ),
    );
  }
}

LogInterceptor _logInterceptor() => LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint('[Dio] $o'),
    );