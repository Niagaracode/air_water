import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import '../../app_startup/app_startup.dart';

class DioClient {
  final Dio _dio;

  DioClient(SecureStorage storage, {required VoidCallback onLogout}) : _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  ) {
    _dio.interceptors.add(AuthInterceptor(storage, onLogout: onLogout));
  }

  Dio get instance => _dio;
}


final dioProvider = Provider((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(
    storage,
    onLogout: () {
      ref.read(appStartupProvider.notifier).setUnauthenticated();
    },
  ).instance;
});
