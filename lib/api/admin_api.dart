import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'client.dart';

part 'admin_api.g.dart';

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);

@RestApi()
abstract class AdminApi {
  factory AdminApi(Dio dio, {String? baseUrl}) = _AdminApi;

  @GET('/admin/users')
  Future<dynamic> listUsers({
    @Query('page') int page = 1,
    @Query('page_size') int pageSize = 50,
    @Query('keyword') String? keyword,
    @Query('role') String? role,
    @Query('is_active') int? isActive,
  });

  @GET('/admin/users/{id}')
  Future<dynamic> getUser(@Path('id') int userId);

  @PATCH('/admin/users/{id}/active')
  Future<void> setUserActive(
    @Path('id') int userId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('/admin/users/{id}/role')
  Future<void> setUserRole(
    @Path('id') int userId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('/admin/users/{id}/permissions')
  Future<dynamic> setUserPermissions(
    @Path('id') int userId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('/admin/users/{id}/quota')
  Future<void> setUserQuota(
    @Path('id') int userId,
    @Body() Map<String, dynamic> body,
  );

  @GET('/admin/stats')
  Future<dynamic> getStats();

  @GET('/admin/configs')
  Future<dynamic> listConfigs();

  @PUT('/admin/configs/{key}')
  Future<dynamic> upsertConfig(
    @Path('key') String key,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/admin/configs/{key}')
  Future<void> deleteConfig(@Path('key') String key);

  @POST('/admin/configs/batch')
  Future<dynamic> batchUpsertConfigs(@Body() Map<String, dynamic> body);

  @GET('/admin/ws/stats')
  Future<dynamic> getWsStats();

  @POST('/admin/ws/push/{userId}')
  Future<void> pushToUser(
    @Path('userId') int userId,
    @Query('message') String message,
  );
}
