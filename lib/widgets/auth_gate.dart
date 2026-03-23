// lib/widgets/auth_gate.dart — 完整替换

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wsListenerProvider); // 保持 WS 生命周期监听
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.checking:
        // 启动检查中：显示品牌 splash
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Vee',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );

      case AuthStatus.authenticated:
        // ✅ 已登录：进入主界面
        return const HomeScreen();

      case AuthStatus.unauthenticated:
        // ✅ 未登录 / Guest：进入主界面（内部各 Tab 根据 isGuest 渲染不同内容）
        // HomeScreen 已通过 PermissionGate / _GuestProfileView 处理 Guest 态
        return const HomeScreen();
    }
  }
}
