import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';
import 'client.dart';
import 'dio_error_mapper.dart';

final billsApiProvider = Provider<BillsApi>((ref) {
  return BillsApi(ref.watch(apiClientProvider));
});

class BillsApi {
  final Dio _dio;
  const BillsApi(this._dio);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw AppException(message: e.toString(), type: AppExceptionType.unknown);
    }
  }

  Future<Map<String, dynamic>> listBills({
    int page = 1,
    int pageSize = 20,
    int? year,
    int? month,
    String? keyword,
  }) =>
      _guard(() async {
        final res = await _dio.get('/bills', queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (year != null) 'year': year,
          if (month != null) 'month': month,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getMonthlySummary({int? year, int? month}) =>
      _guard(() async {
        final res = await _dio.get('/bills/summary', queryParameters: {
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getBill(int billId) =>
      _guard(() => _dio.get('/bills/$billId').then((r) => r.data));

  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) =>
      _guard(() => _dio.post('/bills', data: data).then((r) => r.data));

  Future<Map<String, dynamic>> patchBill(
          int billId, Map<String, dynamic> data) =>
      _guard(
          () => _dio.patch('/bills/$billId', data: data).then((r) => r.data));

  Future<void> deleteBill(int billId) =>
      _guard(() => _dio.delete('/bills/$billId'));

  Future<Map<String, dynamic>> ocrBill(
          String imageBase64, String mimeType) =>
      _guard(() => _dio.post('/bills/ocr', data: {
            'image_base64': imageBase64,
            'mime_type': mimeType,
          }).then((r) => r.data));

  /// 上传图片凭证，返回 { "receipt_url": "..." }
  Future<String> uploadReceipt({
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
  }) =>
      _guard(() async {
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
}