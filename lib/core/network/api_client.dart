import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';


class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<Response> get(String endpoint, {Map<String, dynamic>? query}) {
    print("endpoint:$endpoint, query:$query");
    return _dio.get(endpoint, queryParameters: query);
  }

  Future<Response> post(String endpoint, {dynamic data}) {
    print("endpoint:$endpoint, data:$data");
    return _dio.post(endpoint, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}

final apiClientProvider =
Provider<ApiClient>((ref) => ApiClient(ref.read(dioProvider)));