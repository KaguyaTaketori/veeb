import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';
import '../models/user.dart';
import 'client.dart';
import 'dio_error_mapper.dart';

// 无鉴权（login/register 专用）
final authApiProvider = Provider<AuthApi>((ref) =>
    AuthApi(ref.watch(authClientProvider)));

// 有鉴权（me 相关接口专用）
final meApiProvider = Provider<MeApi>((ref) =>
    MeApi(ref.watch(apiClientProvider)));

// ── 无鉴权接口 ─────────────────────────────────────────────────────────────

class AuthApi {
  final Dio _dio;
  const AuthApi(this._dio);

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) =>
      _guard(() => _dio.post('/auth/register', data: {
            'username': username,
            'email': email,
            'password': password,
            if (displayName != null) 'display_name': displayName,
          }).then((r) => r.data as Map<String, dynamic>));

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) =>
      _guard(() => _dio.post('/auth/verify-email', data: {
            'email': email,
            'code': code,
          }).then((r) => r.data as Map<String, dynamic>));

  Future<Map<String, dynamic>> resendCode(String email) =>
      _guard(() => _dio
          .post('/auth/resend-code', data: {'email': email})
          .then((r) => r.data as Map<String, dynamic>));

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) =>
      _guard(() => _dio.post('/auth/login', data: {
            'identifier': identifier,
            'password': password,
          }).then((r) => r.data as Map<String, dynamic>));

  Future<Map<String, dynamic>> refreshToken(String refreshToken) =>
      _guard(() => _dio
          .post('/auth/refresh', data: {'refresh_token': refreshToken})
          .then((r) => r.data as Map<String, dynamic>));

  Future<void> logout(String refreshToken) =>
      _guard(() => _dio.post('/auth/logout',
          data: {'refresh_token': refreshToken}));

  Future<void> forgotPassword(String email) =>
      _guard(() => _dio.post('/auth/forgot-password', data: {'email': email}));

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _guard(() => _dio.post('/auth/reset-password', data: {
            'email': email,
            'code': code,
            'new_password': newPassword,
          }));
}

// ── 需要鉴权的接口 ─────────────────────────────────────────────────────────

class MeApi {
  final Dio _dio;
  const MeApi(this._dio);

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<UserProfile> getMe() =>
      _guard(() => _dio
          .get('/me')
          .then((r) => UserProfile.fromJson(r.data as Map<String, dynamic>)));

  Future<UserProfile> updateMe({String? displayName, String? avatarUrl}) =>
      _guard(() => _dio.patch('/me', data: {
            if (displayName != null) 'display_name': displayName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          }).then((r) => UserProfile.fromJson(r.data as Map<String, dynamic>)));

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _guard(() => _dio.post('/me/change-password', data: {
            'old_password': oldPassword,
            'new_password': newPassword,
          }));

  // MeApi 末尾追加

  Future<Map<String, dynamic>> requestTgBindCode() =>
      _guard(() => _dio
          .post('/me/tg-bind/request')
          .then((r) => r.data as Map<String, dynamic>));

  Future<void> deleteTgBind() =>
      _guard(() => _dio.delete('/me/tg-bind'));
}