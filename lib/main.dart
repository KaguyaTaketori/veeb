// lib/main.dart（完整替换）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/permission_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/bills_list/bills_list_screen.dart';
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

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 启动 WS 生命周期（登录后自动连接，退出后自动断开）
    ref.watch(wsListenerProvider);

    final authState = ref.watch(authProvider);
    return switch (authState.status) {
      AuthStatus.checking        => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      AuthStatus.authenticated   => const HomeScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

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

    // 动态 tab：管理员多一个「管理」tab
    final screens = [
      const BillsListScreen(),
      const OcrScreen(),
      const StatsScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];

    // 当前 index 超出范围时重置（角色变化时防越界）
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
          // 宽屏：侧边 NavigationRail
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

        // 窄屏：底部 NavigationBar
        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor:
                Theme.of(context).colorScheme.surface,
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


// ============================================================
// 第四步完整落地清单
// ============================================================
//
// 新建文件：
//   lib/services/ws_service.dart          ← WS 连接/断连/重连/心跳
//   lib/providers/permission_provider.dart ← 权限/WS事件/isAdmin Provider
//   lib/widgets/permission_gate.dart       ← PermissionGate 组件
//   lib/api/admin_api.dart                 ← 管理员 API 客户端
//   lib/screens/admin/admin_dashboard_screen.dart ← 管理控制台
//
//
//   lib/models/user.dart
//     - UserProfile 追加 role: String, permissions: List<String>
//     - fromJson 中解析 permissions JSON
//
//   lib/providers/bills_provider.dart
//     - BillsNotifier 追加 insertBillFromWs / updateBillFromWs / removeBillById
//
//   lib/screens/ocr/ocr_screen.dart
//     - body 用 PermissionGate(perm: 'app_ocr') 包裹
//
//   lib/screens/add_edit_bill/add_edit_bill_screen.dart
//     - _ReceiptPicker 用 PermissionGate(perm: 'app_upload') 包裹
//
// pubspec.yaml 追加：
//   web_socket_channel: ^2.4.0
//
// ============================================================