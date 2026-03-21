import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exception.dart';
import '../models/account.dart';
import '../models/group.dart';
import 'client.dart';
import 'dio_error_mapper.dart';
 
final groupsApiProvider = Provider<GroupsApi>(
  (ref) => GroupsApi(ref.watch(apiClientProvider)),
);
 
final accountsApiProvider = Provider<AccountsApi>(
  (ref) => AccountsApi(ref.watch(apiClientProvider)),
);
 
class GroupsApi {
  final Dio _dio;
  const GroupsApi(this._dio);
 
  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
 
  Future<Group> getMyGroup() =>
      _guard(() => _dio.get('/groups/me')
          .then((r) => Group.fromJson(r.data as Map<String, dynamic>)));
 
  Future<Group> createGroup({
    String name         = '我的账本',
    String baseCurrency = 'JPY',
  }) =>
      _guard(() => _dio.post('/groups', data: {
            'name': name,
            'base_currency': baseCurrency,
          }).then((r) => Group.fromJson(r.data as Map<String, dynamic>)));
 
  Future<Group> joinGroup(String inviteCode) =>
      _guard(() => _dio.post('/groups/join',
              queryParameters: {'invite_code': inviteCode})
          .then((r) => Group.fromJson(r.data as Map<String, dynamic>)));
}
 
class AccountsApi {
  final Dio _dio;
  const AccountsApi(this._dio);
 
  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
 
  Future<List<Account>> listAccounts({required int groupId}) =>
      _guard(() async {
        final res = await _dio.get('/accounts',
            queryParameters: {'group_id': groupId});
        return (res.data as List)
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList();
      });
 
  Future<Account> createAccount({
    required String name,
    required String type,
    required String currencyCode,
    required int groupId,
  }) =>
      _guard(() => _dio.post('/accounts', data: {
            'name':          name,
            'type':          type,
            'currency_code': currencyCode,
            'group_id':      groupId,
          }).then((r) => Account.fromJson(r.data as Map<String, dynamic>)));
 
  Future<Account> patchAccount(int id, Map<String, dynamic> data) =>
      _guard(() => _dio.patch('/accounts/$id', data: data)
          .then((r) => Account.fromJson(r.data as Map<String, dynamic>)));
}