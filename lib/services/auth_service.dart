import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_event.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kAccessKey = 'access_token';
  static const _kRefreshKey = 'refresh_token';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAccessToken() => _storage.read(key: _kAccessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshKey);
  Future<bool> get hasTokens async => (await getAccessToken()) != null;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessKey, value: accessToken),
      _storage.write(key: _kRefreshKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _kAccessKey),
      _storage.delete(key: _kRefreshKey),
    ]);
    AuthEventBus.instance.logout();
  }
}
