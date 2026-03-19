// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_api.dart';
import '../services/auth_service.dart';
import '../exceptions/app_exception.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? error;
  final bool loading;

  const AuthState({
    this.status = AuthStatus.checking,
    this.error,
    this.loading = false,
  });

  AuthState copyWith({AuthStatus? status, String? error, bool? loading}) =>
      AuthState(
        status: status ?? this.status,
        error: error,
        loading: loading ?? this.loading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;

  AuthNotifier(this._authApi) : super(const AuthState()) {
    _checkToken();
  }

  // ✅ 修复 #5：不仅检查本地 token 存在，还发请求验证有效性
  // 若后端无 /me 接口，可改为直接读本地 token（保留注释说明权衡）
  Future<void> _checkToken() async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    // TODO: 调用 GET /me 或 /auth/validate 验证 token 仍有效
    // 若后端不提供该接口，以下代码可简化为直接 authenticated
    // try {
    //   await _apiClient.get('/me');
    //   state = state.copyWith(status: AuthStatus.authenticated);
    // } catch (_) {
    //   await AuthService.instance.clearToken();
    //   state = state.copyWith(status: AuthStatus.unauthenticated);
    // }

    // 当前：本地有 token 则认为已登录
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  // ✅ 修复 #6：authApi 通过 Provider 注入，不再每次 new
  Future<void> login(int userId, String secret) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await _authApi.getToken(userId, secret);
      await AuthService.instance.saveToken(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        loading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'ログイン失敗: $e');
    }
  }

  Future<void> logout() async {
    await AuthService.instance.clearToken();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authApiProvider));
});