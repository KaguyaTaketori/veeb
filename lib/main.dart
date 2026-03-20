// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'screens/bills_list/bills_list_screen.dart';
import 'screens/ocr/ocr_screen.dart';
import 'screens/stats/stats_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(
    const ProviderScope(
      child: VeeApp(),
    ),
  );
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

// ✅ ConsumerWidget 替代 StatefulWidget，无需手写 _checking 状态
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState.status) {
      AuthStatus.checking => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userIdCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final userIdText = _userIdCtrl.text.trim();
    final secret = _secretCtrl.text.trim();

    if (userIdText.isEmpty || secret.isEmpty) return;

    final userId = int.tryParse(userIdText);
    if (userId == null) return;

    // ✅ 修复 #6：通过 Provider 调用，不再 new AuthApi(createAuthClient())
    await ref.read(authProvider.notifier).login(userId, secret);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vee',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              TextField(
                controller: _userIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Telegram User ID',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _secretCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Secret', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              if (authState.error != null)
                Text(authState.error!,
                    style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: authState.loading ? null : _login,
                  child: authState.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ログイン'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const[
    BillsListScreen(),
    OcrScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 使用 LayoutBuilder 动态判断屏幕宽度
    return LayoutBuilder(
      builder: (context, constraints) {
        // 如果宽度大于 800px（比如 iPad横屏 或 PC/Mac） -> 使用侧边栏 NavigationRail
        if (constraints.maxWidth > 800) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: Row(
              children:[
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) => setState(() => _currentIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
                  destinations: const[
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('流水'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.camera_alt_outlined),
                      selectedIcon: Icon(Icons.camera_alt),
                      label: Text('記録'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('統計'),
                    ),
                  ],
                ),
                // 右侧加一条极细的分割线
                VerticalDivider(thickness: 1, width: 1, color: Colors.grey.withOpacity(0.2)),
                // 主体内容区域
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          );
        }

        // 如果是手机竖屏 -> 使用原先的底部导航栏 BottomNavigationBar
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const[
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: '流水',
              ),
              NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt),
                label: '記録',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: '統計',
              ),
            ],
          ),
        );
      },
    );
  }
}