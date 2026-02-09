import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  const SecureStorage();

  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'user_role';

  Future<void> saveToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readToken() =>
      _storage.read(key: _accessTokenKey);


  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<void> saveRole(String role) =>
      _storage.write(key: _roleKey, value: role);

  Future<String?> readRole() =>
      _storage.read(key: _roleKey);

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

final secureStorageProvider =
Provider<SecureStorage>((ref) => SecureStorage());