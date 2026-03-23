// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api.dart';
import '../api/groups_api.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import 'package:vee_app/services/sync/sync_coordinator.dart';
import '../exceptions/app_exception.dart';
import 'database_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'auth_provider.freezed.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

@freezed
abstract class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    @Default(AuthStatus.checking) AuthStatus status,
    UserProfile? user,
    String? error,
    @Default(false) bool loading,
  }) = _AuthState;

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.unauthenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  AuthApi get _api => ref.read(authApiProvider);
  MeApi get _meApi => ref.read(meApiProvider);

  // ── 启动初始化 ────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final hasToken = await AuthService.instance.hasTokens;
    if (!hasToken) {
      // 未登录 → 直接进入 Guest 模式，不跳转 LoginScreen
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    await _loadMe();
  }

  Future<void> _loadMe() async {
    try {
      final user = await _meApi.getMe();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null,
      );
    } catch (e) {
      // token 已失效，清除后进入 Guest 模式（而非强制跳 Login）
      await AuthService.instance.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        error: null,
      );
    }
  }

  // ── 登录 ──────────────────────────────────────────────────────────────────

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data =
          await _api.login({'identifier': identifier, 'password': password})
              as Map<String, dynamic>;
      await AuthService.instance.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await _loadMe();

      // 登录成功后把本地未同步数据推送到云端
      await _mergeLocalDataToCloud();

      state = state.copyWith(loading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(loading: false, error: '登录失败，请稍后重试');
      return false;
    }
  }

  // ── 登出 ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final refreshToken = await AuthService.instance.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.logout({'refresh_token': refreshToken});
      } catch (_) {}
    }
    await AuthService.instance.clearTokens();
    // 退出后回到 Guest 模式，保留本地数据
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── 刷新用户信息 ──────────────────────────────────────────────────────────

  Future<void> refreshProfile() => _loadMe();

  void clearError() => state = state.copyWith(error: null);

  // ── Telegram 绑定 ─────────────────────────────────────────────────────────

  Future<dynamic> requestTgBindCode() async {
    return await _meApi.requestTgBindCode() as Map<String, dynamic>;
  }

  Future<void> deleteTgBind() async {
    await _meApi.deleteTgBind();
    await _loadMe();
  }

  // ── 用户信息更新 ─────────────────────────────────────────────────────────

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final user = await _meApi.updateMe(body);
    state = state.copyWith(user: user);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _meApi.changePassword({
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // ── 登录后合并本地数据 ────────────────────────────────────────────────────

  Future<void> _mergeLocalDataToCloud() async {
    try {
      final groupsApi = ref.read(groupsApiProvider);
      Group? cloudGroup;
      try {
        cloudGroup = await groupsApi.getMyGroup();
      } catch (_) {
        cloudGroup = await groupsApi.createGroup({
          'name': '我的账本',
          'base_currency': 'JPY',
        });
      }

      final db = ref.read(appDatabaseProvider);
      await db.markAllLocalAsPending();

      // ✅ 统一使用 SyncCoordinator，彻底删除 SyncService 的调用
      final coordinator = ref.read(syncCoordinatorProvider);
      await coordinator.syncNow();
    } catch (e) {
      print('[Auth] 本地数据合并失败（非致命）: $e');
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
