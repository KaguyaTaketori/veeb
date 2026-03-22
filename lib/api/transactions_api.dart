// lib/api/transactions_api.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';
import '../models/transaction.dart';
import 'client.dart';
import 'dio_error_mapper.dart';

final transactionsApiProvider = Provider<TransactionsApi>(
  (ref) => TransactionsApi(ref.watch(apiClientProvider)),
);

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiClientProvider)),
);

class TransactionsApi {
  final Dio _dio;
  const TransactionsApi(this._dio);

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

  Future<Map<String, dynamic>> listTransactions({
    required int groupId,
    int page = 1,
    int pageSize = 20,
    int? year,
    int? month,
    String? type,
    int? accountId,
    String? keyword,
    double? updatedAfter,
  }) => _guard(() async {
    final res = await _dio.get(
      '/transactions',
      queryParameters: {
        'group_id': groupId,
        'page': page,
        'page_size': pageSize,
        if (year != null) 'year': year,
        if (month != null) 'month': month,
        if (type != null) 'type': type,
        if (accountId != null) 'account_id': accountId,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (updatedAfter != null) 'updated_after': updatedAfter,
      },
    );
    return res.data as Map<String, dynamic>;
  });

  Future<Transaction> getTransaction(int id) => _guard(
    () => _dio
        .get('/transactions/$id')
        .then((r) => Transaction.fromJson(r.data as Map<String, dynamic>)),
  );

  /// 创建流水。
  /// [data] 中的 payee 字段会直接透传到服务端。
  /// 服务端若尚未支持 payee 字段，会静默忽略，不会报错。
  Future<Transaction> createTransaction(Map<String, dynamic> data) => _guard(
    () => _dio
        .post('/transactions', data: data)
        .then((r) => Transaction.fromJson(r.data as Map<String, dynamic>)),
  );

  Future<Transaction> patchTransaction(int id, Map<String, dynamic> data) =>
      _guard(
        () => _dio
            .patch('/transactions/$id', data: data)
            .then((r) => Transaction.fromJson(r.data as Map<String, dynamic>)),
      );

  Future<void> deleteTransaction(int id) =>
      _guard(() => _dio.delete('/transactions/$id'));

  Future<MonthlyStat> getMonthlySummary({
    required int groupId,
    int? year,
    int? month,
  }) => _guard(() async {
    final res = await _dio.get(
      '/transactions/summary',
      queryParameters: {
        'group_id': groupId,
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );
    return MonthlyStat.fromJson(res.data as Map<String, dynamic>);
  });

  Future<String> uploadReceipt({
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
  }) => _guard(() async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final res = await _dio.post('/uploads/receipt', data: formData);
    return res.data['receipt_url'] as String;
  });

  /// OCR 识别（不入库，返回解析结果）
  /// 服务端返回的 payee 字段由 Transaction.fromJson 的
  /// `j['payee'] ?? j['merchant']` 兼容逻辑处理。
  Future<Map<String, dynamic>> ocrTransaction(
    String imageBase64,
    String mimeType,
  ) => _guard(
    () => _dio
        .post(
          '/transactions/ocr',
          data: {'image_base64': imageBase64, 'mime_type': mimeType},
        )
        .then((r) => r.data as Map<String, dynamic>),
  );
}

class CategoriesApi {
  final Dio _dio;
  const CategoriesApi(this._dio);

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Category>> listCategories({int? groupId}) => _guard(() async {
    final res = await _dio.get(
      '/categories',
      queryParameters: {if (groupId != null) 'group_id': groupId},
    );
    return (res.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<Category> createCategory(Map<String, dynamic> data) => _guard(
    () => _dio
        .post('/categories', data: data)
        .then((r) => Category.fromJson(r.data as Map<String, dynamic>)),
  );

  Future<void> deleteCategory(int id) =>
      _guard(() => _dio.delete('/categories/$id'));

  Future<Category> patchCategory(int id, Map<String, dynamic> data) => _guard(
    () => _dio
        .patch('/categories/$id', data: data)
        .then((r) => Category.fromJson(r.data as Map<String, dynamic>)),
  );
}
