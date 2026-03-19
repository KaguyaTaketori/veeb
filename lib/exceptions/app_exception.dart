
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final AppExceptionType type;

  const AppException({
    required this.message,
    this.statusCode,
    this.type = AppExceptionType.unknown,
  });

  @override
  String toString() => message;
}

enum AppExceptionType {
  network,
  unauthorized,
  server,
  notFound,
  badRequest,
  unknown,
}