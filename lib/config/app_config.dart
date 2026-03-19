// lib/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://217.142.236.17:8000/v1';

  static String get authBaseUrl => dotenv.env['API_AUTH_BASE_URL'] ?? 'http://217.142.236.17:8000';

  static String get authTokenPath => '/auth/token';

  static bool get isDebug => !const bool.fromEnvironment('dart.vm.product', defaultValue: false);
}
