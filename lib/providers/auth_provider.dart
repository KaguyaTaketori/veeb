// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api.dart';
import '../api/groups_api.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../exceptions/app_exception.dart';
import 'database_provider.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? error;
  final bool loading;

  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.error,
    this.loading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? error,
    bool? loading,
    bool clearError = false,
    bool clearUser  = false,
  }) =>
      AuthState(
        status:  status  ?? this.status,
        user:    clearUser  ? null : (user  ?? this.user),
        error:   clearError ? null : (error ?? this.error),
        loading: loading ?? this.loading,
      );

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isGuest    => status == AuthStatus.unauthenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  AuthApi get _api   => ref.read(authApiProvider);
  MeApi  get _meApi  => ref.read(meApiProvider);

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
        user:   user,
        clearError: true,
      );
    } catch (e) {
      // token 已失效，清除后进入 Guest 模式（而非强制跳 Login）
      await AuthService.instance.clearTokens();
      state = state.copyWith(
        status:    AuthStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      );
    }
  }

  // ── 登录 ──────────────────────────────────────────────────────────────────

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await _api.login(
        identifier: identifier,
        password:   password,
      );
      await AuthService.instance.saveTokens(
        accessToken:  data['access_token']  as String,
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
      try { await _api.logout(refreshToken); } catch (_) {}
    }
    await AuthService.instance.clearTokens();
    // 退出后回到 Guest 模式，保留本地数据
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── 刷新用户信息 ──────────────────────────────────────────────────────────

  Future<void> refreshProfile() => _loadMe();

  void clearError() => state = state.copyWith(clearError: true);

  // ── Telegram 绑定 ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestTgBindCode() async {
    return await _meApi.requestTgBindCode();
  }

  Future<void> deleteTgBind() async {
    await _meApi.deleteTgBind();
    await _loadMe();
  }

  // ── 用户信息更新 ─────────────────────────────────────────────────────────

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    final user = await _meApi.updateMe(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    state = state.copyWith(user: user);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _meApi.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  // ── 登录后合并本地数据 ────────────────────────────────────────────────────

  Future<void> _mergeLocalDataToCloud() async {
    try {
      // 1. 拉取或创建云端 group
      final groupsApi = ref.read(groupsApiProvider);
      Group? cloudGroup;
      try {
        cloudGroup = await groupsApi.getMyGroup();
      } catch (_) {
        // 云端没有 group，用本地 group 信息创建
        cloudGroup = await groupsApi.createGroup();
      }

      // 2. 把本地 DB 里 remoteId == null 的记录标记为 pending_create
      final db = ref.read(appDatabaseProvider);
      await db.markAllLocalAsPending();

      // 3. 触发同步
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncNow();

    } catch (e) {
      // 合并失败不影响登录本身，只记录日志
      // ignore: avoid_print
      print('[Auth] 本地数据合并失败（非致命）: $e');
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());