// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/permission_provider.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/ocr/ocr_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: VeeApp()));
}

class VeeApp extends StatelessWidget {
  const VeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D30),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ── AuthGate ─────────────────────────────────────────────────────────────────
// 不再强制登录，checking 状态结束后无论是否登录都进入 HomeScreen

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 启动 WS 生命周期（已登录时自动连接，退出后自动断开）
    ref.watch(wsListenerProvider);

    final authState = ref.watch(authProvider);

    // 启动检查期间显示 splash（通常很短，< 500ms）
    if (authState.status == AuthStatus.checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vee',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
    }

    // checking 结束后无论 authenticated / unauthenticated 都进主界面
    return const HomeScreen();
  }
}

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    final screens = [
      const TransactionsScreen(),
      const OcrScreen(),
      const StatsScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    final destinations = [
      const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: '流水'),
      const NavigationDestination(
          icon: Icon(Icons.camera_alt_outlined),
          selectedIcon: Icon(Icons.camera_alt),
          label: '记录'),
      const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: '统计'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '我的'),
      if (isAdmin)
        const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: '管理'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _currentIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor:
                      Theme.of(context).colorScheme.surface,
                  destinations: destinations
                      .map((d) => NavigationRailDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon ?? d.icon,
                            label: Text(d.label),
                          ))
                      .toList(),
                ),
                VerticalDivider(
                    thickness: 1,
                    width: 1,
                    color: Colors.grey.withOpacity(0.2)),
                Expanded(child: screens[_currentIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            destinations: destinations,
          ),
        );
      },
    );
  }
}