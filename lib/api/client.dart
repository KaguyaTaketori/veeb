// lib/api/client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../exceptions/app_exception.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await AuthService.instance.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await AuthService.instance.clearToken();
        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: const AppException(
              message: 'セッションが期限切れです。再ログインしてください',
              statusCode: 401,
              type: AppExceptionType.unauthorized,
            ),
          ),
        );
      }
      return handler.next(error);
    },
  ));

  if (AppConfig.isDebug) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint('[Dio] $o'),
    ));
  }

  return dio;
});

final authClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.authBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  if (AppConfig.isDebug) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint('[Dio] $o'),
    ));
  }

  return dio;
});