// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api.dart';
import '../exceptions/app_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/auth_event.dart';

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
    final sub = AuthEventBus.instance.stream.listen((event) {
      if (event == AuthEvent.logout) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });

    ref.onDispose(sub.cancel);
    
    _init();
    return const AuthState();
  }

  AuthApi get _api => ref.read(authApiProvider);
  MeApi  get _meApi  => ref.read(meApiProvider);

  Future<void> _init() async {
    final hasToken = await AuthService.instance.hasTokens;
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    // 有 refresh token，尝试获取用户信息（顺带验证 access token）
    await _loadMe();
  }

  Future<void> _loadMe() async {
    try {
      final user = await _meApi.getMe();            // ← 改这里
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      final hasToken = await AuthService.instance.hasTokens;
      if (!hasToken) {
        state = state.copyWith(
            status: AuthStatus.unauthenticated, clearUser: true);
      } else {
        try {
          final user = await _meApi.getMe();        // ← 改这里
          state = state.copyWith(
              status: AuthStatus.authenticated, user: user);
        } catch (_) {
          await AuthService.instance.clearTokens();
          state = state.copyWith(
              status: AuthStatus.unauthenticated, clearUser: true);
        }
      }
    }
  }


  Future<void> login(String identifier, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await _api.login(identifier: identifier, password: password);
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

  Future<void> logout() async {
    final refreshToken = await AuthService.instance.getRefreshToken();
    if (refreshToken != null) {
      try { await _api.logout(refreshToken); } catch (_) {}
    }
    await AuthService.instance.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile() => _loadMe();

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());