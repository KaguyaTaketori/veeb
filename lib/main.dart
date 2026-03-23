import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/vee_app.dart';
import 'providers/permission_provider.dart'; // wsLifecycleProvider

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(
    ProviderScope(
      overrides: [],
      child: Consumer(
        builder: (context, ref, _) {
          ref.watch(wsLifecycleProvider);
          return const VeeApp();
        },
      ),
    ),
  );
}
