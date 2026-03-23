import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import '../models/user.dart';
import 'client.dart';

part 'auth_api.g.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(authClientProvider)),
);

final meApiProvider = Provider<MeApi>(
  (ref) => MeApi(ref.watch(apiClientProvider)),
);

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  @POST('/auth/register')
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @POST('/auth/verify-email')
  Future<dynamic> verifyEmail(@Body() Map<String, dynamic> body);

  @POST('/auth/resend-code')
  Future<dynamic> resendCode(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST('/auth/refresh')
  Future<dynamic> refreshToken(@Body() Map<String, dynamic> body);

  @POST('/auth/logout')
  Future<void> logout(@Body() Map<String, dynamic> body);

  @POST('/auth/forgot-password')
  Future<void> forgotPassword(@Body() Map<String, dynamic> body);

  @POST('/auth/reset-password')
  Future<void> resetPassword(@Body() Map<String, dynamic> body);
}

@RestApi()
abstract class MeApi {
  factory MeApi(Dio dio, {String? baseUrl}) = _MeApi;

  @GET('/me')
  Future<UserProfile> getMe();

  @PATCH('/me')
  Future<UserProfile> updateMe(@Body() Map<String, dynamic> body);

  @POST('/me/change-password')
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @POST('/me/tg-bind/request')
  Future<dynamic> requestTgBindCode();

  @DELETE('/me/tg-bind')
  Future<void> deleteTgBind();
}
