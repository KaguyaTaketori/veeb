import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';
import 'client.dart';
import 'dio_error_mapper.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(authClientProvider));
});

class AuthApi {
  final Dio _dio;
  const AuthApi(this._dio);

  Future<String> getToken(int userId, String secret) async {
    try {
      final res = await _dio.post(
        '/auth/token',
        data: {'user_id': userId, 'secret': secret},
      );
      final token = res.data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AppException(
          message: 'サーバーからトークンを取得できませんでした',
          type: AppExceptionType.server,
        );
      }
      return token;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}