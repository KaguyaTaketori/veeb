import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import '../models/transaction.dart';
import 'client.dart';

part 'transactions_api.g.dart';

final transactionsApiProvider = Provider<TransactionsApi>(
  (ref) => TransactionsApi(ref.watch(apiClientProvider)),
);

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(apiClientProvider)),
);

@RestApi()
abstract class TransactionsApi {
  factory TransactionsApi(Dio dio, {String? baseUrl}) = _TransactionsApi;

  @GET('/transactions')
  Future<dynamic> listTransactions(
    @Query('group_id') int groupId, {
    @Query('page') int page = 1,
    @Query('page_size') int pageSize = 20,
    @Query('year') int? year,
    @Query('month') int? month,
    @Query('type') String? type,
    @Query('account_id') int? accountId,
    @Query('keyword') String? keyword,
    @Query('updated_after') double? updatedAfter,
  });

  @GET('/transactions/{id}')
  Future<Transaction> getTransaction(@Path('id') int id);

  @POST('/transactions')
  Future<Transaction> createTransaction(@Body() Map<String, dynamic> data);

  @PATCH('/transactions/{id}')
  Future<Transaction> patchTransaction(
    @Path('id') int id,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/transactions/{id}')
  Future<void> deleteTransaction(@Path('id') int id);

  @GET('/transactions/summary')
  Future<MonthlyStat> getMonthlySummary(
    @Query('group_id') int groupId, {
    @Query('year') int? year,
    @Query('month') int? month,
  });

  @POST('/uploads/receipt')
  @MultiPart()
  Future<dynamic> uploadReceiptRaw(
    @Part(name: 'file') List<int> fileBytes, {
    @Part(name: 'filename') String? filename,
  });

  @POST('/transactions/ocr')
  Future<dynamic> ocrTransaction(@Body() Map<String, dynamic> body);
}

@RestApi()
abstract class CategoriesApi {
  factory CategoriesApi(Dio dio, {String? baseUrl}) = _CategoriesApi;

  @GET('/categories')
  Future<List<Category>> listCategories({@Query('group_id') int? groupId});

  @POST('/categories')
  Future<Category> createCategory(@Body() Map<String, dynamic> data);

  @DELETE('/categories/{id}')
  Future<void> deleteCategory(@Path('id') int id);

  @PATCH('/categories/{id}')
  Future<Category> patchCategory(
    @Path('id') int id,
    @Body() Map<String, dynamic> data,
  );
}
