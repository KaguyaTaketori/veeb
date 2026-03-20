// lib/api/admin_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';
import 'client.dart';
import 'dio_error_mapper.dart';

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);

class AdminApi {
  final Dio _dio;
  const AdminApi(this._dio);

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw AppException(message: e.toString(), type: AppExceptionType.unknown);
    }
  }

  // ── 用户管理 ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listUsers({
    int page = 1,
    int pageSize = 50,
    String? keyword,
    String? role,
    int? isActive,
  }) =>
      _guard(() async {
        final res = await _dio.get('/admin/users', queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (role != null) 'role': role,
          if (isActive != null) 'is_active': isActive,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getUser(int userId) =>
      _guard(() => _dio.get('/admin/users/$userId').then((r) => r.data));

  Future<void> setUserActive(int userId, {required bool isActive}) =>
      _guard(() => _dio.patch('/admin/users/$userId/active',
          data: {'is_active': isActive}));

  Future<void> setUserRole(int userId, String role) =>
      _guard(() => _dio.patch('/admin/users/$userId/role',
          data: {'role': role}));

  Future<Map<String, dynamic>> setUserPermissions(
    int userId,
    List<String> permissions,
  ) =>
      _guard(() => _dio
          .patch('/admin/users/$userId/permissions',
              data: {'permissions': permissions})
          .then((r) => r.data));

  Future<void> setUserQuota(int userId, int quota) =>
      _guard(() => _dio.patch('/admin/users/$userId/quota',
          data: {'ai_quota_monthly': quota}));

  // ── 全局统计 ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() =>
      _guard(() => _dio.get('/admin/stats').then((r) => r.data));

  // ── 系统配置 ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listConfigs() =>
      _guard(() => _dio.get('/admin/configs').then((r) => r.data));

  Future<Map<String, dynamic>> upsertConfig(
    String key,
    String value, {
    String? description,
  }) =>
      _guard(() => _dio
          .put('/admin/configs/$key', data: {
            'config_value': value,
            if (description != null) 'description': description,
          })
          .then((r) => r.data));

  Future<void> deleteConfig(String key) =>
      _guard(() => _dio.delete('/admin/configs/$key'));

  Future<Map<String, dynamic>> batchUpsertConfigs(
      Map<String, String> configs) =>
      _guard(() => _dio
          .post('/admin/configs/batch', data: {'configs': configs})
          .then((r) => r.data));

  // ── WS 推送 ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWsStats() =>
      _guard(() => _dio.get('/admin/ws/stats').then((r) => r.data));

  Future<void> pushToUser(int userId, String message) =>
      _guard(() => _dio.post('/admin/ws/push/$userId',
          queryParameters: {'message': message}));
}