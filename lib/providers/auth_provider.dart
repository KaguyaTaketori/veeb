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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkToken();
    return const AuthState();
  }

  AuthApi get _authApi => ref.watch(authApiProvider);

  Future<void> _checkToken() async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    state = state.copyWith(status: AuthStatus.authenticated);
  }

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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
