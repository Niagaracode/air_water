import 'dart:async';
import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  final SecureStorage storage;
  final Dio dio;

  bool _isRefreshing = false;
  final List<Completer<void>> _queue = [];

  RefreshTokenInterceptor(this.storage, this.dio);

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode == 401) {
      final completer = Completer<void>();
      _queue.add(completer);

      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshToken = await storage.readRefreshToken();

          final response = await dio.post(
            '/user_config/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newToken = response.data['accessToken'];

          await storage.saveToken(newToken);

          for (final c in _queue) {
            c.complete();
          }
          _queue.clear();
        } catch (e) {
          await storage.clear();

          for (final c in _queue) {
            c.completeError(e);
          }
          _queue.clear();
        } finally {
          _isRefreshing = false;
        }
      }

      try {
        await completer.future;

        final opts = err.requestOptions;
        opts.headers['Authorization'] =
        'Bearer ${await storage.readToken()}';

        final cloned = await dio.fetch(opts);
        return handler.resolve(cloned);
      } catch (_) {
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }
}