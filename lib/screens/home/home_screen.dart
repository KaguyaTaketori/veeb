// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vee_app/widgets/ui_core/vee_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permission_provider.dart';
import '../../l10n/app_localizations.dart';
import '../transactions/transactions_screen.dart';
import '../ocr/ocr_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);

    final destinations = [
      NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.transactions),
      NavigationDestination(
          icon: const Icon(Icons.camera_alt_outlined),
          selectedIcon: const Icon(Icons.camera_alt),
          label: l10n.record),
      NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: l10n.stats),
      NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.profile),
      if (isAdmin)
        NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: const Icon(Icons.admin_panel_settings),
            label: l10n.admin),
    ];

    final screens = [
      const TransactionsScreen(),
      const OcrScreen(),
      const StatsScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];

    return _HomeScreenContent(
      destinations: destinations,
      screens: screens,
    );
  }
}

class _HomeScreenContent extends ConsumerStatefulWidget {
  final List<NavigationDestination> destinations;
  final List<Widget> screens;

  const _HomeScreenContent({
    required this.destinations,
    required this.screens,
  });

  @override
  ConsumerState<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<_HomeScreenContent> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.screens.length) {
      _currentIndex = 0;
    }

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
                  destinations: widget.destinations
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
                    color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: VeeTokens.durationNormal,
                    switchInCurve:  Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: widget.screens[_currentIndex],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: AnimatedSwitcher(
            duration: VeeTokens.durationNormal,
            switchInCurve:  Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: widget.screens[_currentIndex],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            destinations: widget.destinations,
          ),
        );
      },
    );
  }
}
