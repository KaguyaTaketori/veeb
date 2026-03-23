import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../models/transaction.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/add_edit_transaction_screen.dart';
import '../screens/ocr/ocr_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/settings/manage_accounts_screen.dart';
import '../screens/settings/manage_categories_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // authProvider の変化を go_router に通知するための ValueNotifier
  final notifier = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen(authProvider, (_, next) => notifier.value = next);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/transactions',
    refreshListenable: notifier,

    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final isChecking = auth.status == AuthStatus.checking;

      // 起動中は何もしない
      if (isChecking) return null;

      final authRoutes = [
        '/login',
        '/register',
        '/verify-email',
        '/forgot-password',
      ];
      final isOnAuthRoute = authRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      // 未認証でアプリ内ページ → /login へ
      if (!isAuth && !isOnAuthRoute) return '/login';

      // 認証済みで認証ページ → /transactions へ
      if (isAuth && isOnAuthRoute) return '/transactions';

      // 管理画面への不正アクセスを防ぐ
      if (state.matchedLocation.startsWith('/admin')) {
        final isAdmin = ref.read(isAdminProvider);
        if (!isAdmin) return '/transactions';
      }

      return null;
    },

    routes: [
      // ── 認証フロー ─────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VerifyEmailScreen(
            email: extra['email'] as String,
            debugCode: extra['debug_code'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── メイン（ボトムナビ）────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, __) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/ocr', builder: (_, __) => const OcrScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => EditProfileScreen(
                      user: (state.extra as Map<String, dynamic>)['user'],
                    ),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (_, __) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'accounts',
                    builder: (_, __) => const ManageAccountsScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (_, __) => const ManageCategoriesScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, __) => const AdminDashboardScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── トップレベル（ボトムナビ外）────────────────────────────────────────
      GoRoute(
        path: '/transaction-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddEditTransactionScreen(
            transaction: extra['transaction'] as Transaction,
            isReadOnly: extra['isReadOnly'] as bool? ?? true,
          );
        },
      ),
    ],
  );
});
