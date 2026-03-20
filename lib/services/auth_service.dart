import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kTokenKey = 'jwt_token';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getToken() => _storage.read(key: _kTokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _kTokenKey);

  Future<bool> get isLoggedIn async => (await getToken()) != null;
}