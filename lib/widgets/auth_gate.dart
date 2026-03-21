// lib/widgets/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../screens/home/home_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wsListenerProvider);

    final authState = ref.watch(authProvider);

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

    return const HomeScreen();
  }
}
