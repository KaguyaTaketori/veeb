import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import '../models/account.dart';
import '../models/group.dart';
import 'client.dart';

part 'groups_api.g.dart';

final groupsApiProvider = Provider<GroupsApi>(
  (ref) => GroupsApi(ref.watch(apiClientProvider)),
);

final accountsApiProvider = Provider<AccountsApi>(
  (ref) => AccountsApi(ref.watch(apiClientProvider)),
);

@RestApi()
abstract class GroupsApi {
  factory GroupsApi(Dio dio, {String? baseUrl}) = _GroupsApi;

  @GET('/groups/me')
  Future<Group> getMyGroup();

  @POST('/groups')
  Future<Group> createGroup(@Body() Map<String, dynamic> body);

  @POST('/groups/join')
  Future<Group> joinGroup(@Query('invite_code') String inviteCode);
}

@RestApi()
abstract class AccountsApi {
  factory AccountsApi(Dio dio, {String? baseUrl}) = _AccountsApi;

  @GET('/accounts')
  Future<List<Account>> listAccounts(@Query('group_id') int groupId);

  @POST('/accounts')
  Future<Account> createAccount(@Body() Map<String, dynamic> data);

  @PATCH('/accounts/{id}')
  Future<Account> patchAccount(
    @Path('id') int id,
    @Body() Map<String, dynamic> data,
  );
}
