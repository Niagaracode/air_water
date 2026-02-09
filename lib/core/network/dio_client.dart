import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  final Dio _dio;

  DioClient(SecureStorage storage) : _dio = Dio() {
    _dio.interceptors.add(AuthInterceptor(storage));
  }

  Dio get instance => _dio;
}

final dioProvider = Provider((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(storage).instance;
});
