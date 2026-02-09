import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repository/auth_repository.dart';
import '../api/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _api;
  final SecureStorage _storage;

  AuthRepositoryImpl(this._api, this._storage);

  @override
  Future<void> login(String username, String password) async {
    try {
      final res = await _api.login(username, password);

      final token = res['token'];
      if (token != null) {
        await _storage.saveToken(token.toString());
      }

      final user = res['user'];
      if (user != null && user is Map) {
        final role = user['role_name'];
        if (role != null) {
          await _storage.saveRole(role.toString());
        }
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : null;

      if (status == 401 || status == 403) {
        throw AppException(message ?? 'Invalid username or password');
      }

      if (status == 404) {
        throw AppException(message ?? 'Login service not available');
      }

      throw AppException(message ?? 'Network error. Please try again');
    }
  }

  @override
  Future<void> logout() async {
    await _storage.clear();
  }

  @override
  Future<String?> getUserRole() async {
    return await _storage.readRole();
  }
}