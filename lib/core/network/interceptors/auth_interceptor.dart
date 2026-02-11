import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage storage;

  AuthInterceptor(this.storage);

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

    options.headers.putIfAbsent(
      'Content-Type', () => 'application/json',
    );

    return handler.next(options);
  }
}
