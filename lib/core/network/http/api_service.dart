import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';


class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<Response> get(String endpoint, {Map<String, dynamic>? query}) {

    debugPrint("Base URL: ${_dio.options.baseUrl}");
    debugPrint("Endpoint: $endpoint");
    debugPrint("Full URL: ${_dio.options.baseUrl}$endpoint");
    debugPrint("Query: $query");

    return _dio.get(endpoint, queryParameters: query);
  }

  Future<Response> post(String endpoint, {dynamic data}) {
    debugPrint("Full URL: ${_dio.options.baseUrl}$endpoint");
    debugPrint("data: $data");
    return _dio.post(endpoint, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}

final apiClientProvider = Provider<ApiService>((ref) => ApiService(ref.read(dioProvider)));