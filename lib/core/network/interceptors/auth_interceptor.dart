import 'dart:ui';
import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage storage;
  final VoidCallback onLogout;

  AuthInterceptor(this.storage, {required this.onLogout});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login
    if (options.path.contains('/login')) {
      return handler.next(options);
    }

    final token = await storage.readToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers.putIfAbsent('Content-Type', () => 'application/json');

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      onLogout();
    }
    super.onError(err, handler);
  }
}
