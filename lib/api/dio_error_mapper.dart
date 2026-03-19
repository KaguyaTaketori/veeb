import 'package:dio/dio.dart';
import '../exceptions/app_exception.dart';

AppException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const AppException(
        message: 'ネットワーク接続がタイムアウトしました',
        type: AppExceptionType.network,
      );
    case DioExceptionType.connectionError:
      return const AppException(
        message: 'サーバーに接続できません。ネットワークを確認してください',
        type: AppExceptionType.network,
      );
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 401) {
        return const AppException(
          message: 'セッションが期限切れです。再ログインしてください',
          statusCode: 401,
          type: AppExceptionType.unauthorized,
        );
      }
      if (status == 404) {
        return const AppException(
          message: 'リソースが見つかりません',
          statusCode: 404,
          type: AppExceptionType.notFound,
        );
      }
      if (status != null && status >= 500) {
        return AppException(
          message: 'サーバーエラーが発生しました（$status）',
          statusCode: status,
          type: AppExceptionType.server,
        );
      }
      final msg = e.response?.data?['detail'] ?? e.message ?? '不明なエラー';
      return AppException(
        message: msg.toString(),
        statusCode: status,
        type: AppExceptionType.badRequest,
      );
    default:
      return AppException(
        message: e.message ?? '不明なエラーが発生しました',
        type: AppExceptionType.unknown,
      );
  }
}