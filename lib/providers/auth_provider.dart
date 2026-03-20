// lib/providers/auth_provider.dart  （完整替换）
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../exceptions/app_exception.dart';

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
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  AuthApi get _api   => ref.read(authApiProvider);
  MeApi  get _meApi  => ref.read(meApiProvider);

  // ── 启动时检查本地 token ──────────────────────────────────────────────

  Future<void> _init() async {
    final hasToken = await AuthService.instance.hasTokens;
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    await _loadMe();
  }

  // ── 加载用户信息（简化版：不做双重重试，由拦截器负责 token 刷新）───────

  Future<void> _loadMe() async {
    try {
      final user = await _meApi.getMe();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user:   user,
        clearError: true,
      );
    } catch (e) {
      // 拦截器已经尝试过刷新 token：
      //   - 刷新成功 → retry 成功 → 不会走到这里
      //   - 刷新成功 → retry 仍 401 → 拦截器清除 token，抛出异常 → 走这里
      //   - 刷新失败 → 拦截器清除 token，抛出异常 → 走这里
      // 所以走到这里时，token 已经被拦截器清除了，直接登出即可
      await AuthService.instance.clearTokens();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      );
    }
  }

  // ── 登录 ──────────────────────────────────────────────────────────────

  Future<void> login(String identifier, String password) async {
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
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: '登录失败，请稍后重试');
    }
  }

  // ── 退出登录 ──────────────────────────────────────────────────────────

  Future<void> logout() async {
    final refreshToken = await AuthService.instance.getRefreshToken();
    if (refreshToken != null) {
      try { await _api.logout(refreshToken); } catch (_) {}
    }
    await AuthService.instance.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── 刷新用户信息 ──────────────────────────────────────────────────────

  Future<void> refreshProfile() => _loadMe();

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());