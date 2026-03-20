// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';          // ← 新登录页
import 'screens/bills_list/bills_list_screen.dart';
import 'screens/ocr/ocr_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/profile/profile_screen.dart';

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
    final authState = ref.watch(authProvider);
    return switch (authState.status) {
      AuthStatus.checking        => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      AuthStatus.authenticated   => const HomeScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    BillsListScreen(),
    OcrScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  destinations: const [
                    NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: Text('流水')),
                    NavigationRailDestination(
                        icon: Icon(Icons.camera_alt_outlined),
                        selectedIcon: Icon(Icons.camera_alt),
                        label: Text('记录')),
                    NavigationRailDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart),
                        label: Text('统计')),
                    NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('我的')),
                  ],
                ),
                VerticalDivider(
                    thickness: 1,
                    width: 1,
                    color: Colors.grey.withOpacity(0.2)),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: '流水'),
              NavigationDestination(
                  icon: Icon(Icons.camera_alt_outlined),
                  selectedIcon: Icon(Icons.camera_alt),
                  label: '记录'),
              NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: '统计'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '我的'),
            ],
          ),
        );
      },
    );
  }
}