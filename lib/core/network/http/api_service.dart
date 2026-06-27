import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'dio_client.dart';
import '../../constants/app_constants.dart';


class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  String encryptPayload(String plainText) {
    try {
      final key = enc.Key.fromUtf8(AppConstants.encryptionKey);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return "${iv.base16}:${encrypted.base16}";
    } catch (e) {
      debugPrint("Encryption error: $e");
      rethrow;
    }
  }

  String decryptPayload(String encryptedText) {
    try {
      final key = enc.Key.fromUtf8(AppConstants.encryptionKey);
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception("Invalid encrypted text format");
      }
      final iv = enc.IV.fromBase16(parts[0]);
      final encrypted = enc.Encrypted.fromBase16(parts[1]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint("Decryption error: $e");
      rethrow;
    }
  }

  void _decryptResponse(Response response) {
    if (response.data != null && response.data is Map) {
      final responseMap = response.data as Map;
      if (responseMap.containsKey('data')) {
        final encryptedData = responseMap['data'];
        if (encryptedData is String && encryptedData.contains(':')) {
          try {
            final decryptedJson = decryptPayload(encryptedData);
            final decryptedData = jsonDecode(decryptedJson);
            response.data = decryptedData;
          } catch (e) {
            debugPrint("Failed to decrypt response: $e");
          }
        }
      }
    }
  }

  String _encryptPathSegments(String path) {
    final urlParts = path.split('?');
    final pathPart = urlParts[0];
    final queryPart = urlParts.length > 1 ? urlParts[1] : null;

    final segments = pathPart.split('/');
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.isNotEmpty && int.tryParse(segment) != null) {
        segments[i] = Uri.encodeComponent(encryptPayload(segment));
      }
    }

    final encryptedPath = segments.join('/');
    return queryPart != null ? '$encryptedPath?$queryPart' : encryptedPath;
  }

  Future<Response> get(String endpoint, {Map<String, dynamic>? query}) async {
    final encryptedPath = _encryptPathSegments(endpoint);
    debugPrint("Full URL: ${_dio.options.baseUrl}$encryptedPath");
    debugPrint("Query: $query");
    final response = await _dio.get(encryptedPath, queryParameters: query);
    _decryptResponse(response);
    return response;
  }

  Future<Response> download(String endpoint, {Map<String, dynamic>? query}) async {
    final encryptedPath = _encryptPathSegments(endpoint);
    debugPrint("Full URL: ${_dio.options.baseUrl}$encryptedPath");
    debugPrint("Query: $query");
    final response = await _dio.get(
      encryptedPath,
      queryParameters: query,
      options: Options(
        responseType: ResponseType.bytes,
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    return response;
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    final encryptedPath = _encryptPathSegments(endpoint);
    debugPrint("Full URL: ${_dio.options.baseUrl}$encryptedPath");
    debugPrint("data: $data");
    dynamic requestData = data;
    if (data != null && data is! FormData) {
      final plainTextJson = jsonEncode(data);
      final encryptedString = encryptPayload(plainTextJson);
      requestData = {'data': encryptedString};
    }
    final response = await _dio.post(encryptedPath, data: requestData);
    _decryptResponse(response);
    return response;
  }

  Future<Response> put(String path, {dynamic data}) async {
    final encryptedPath = _encryptPathSegments(path);
    debugPrint("Full URL: ${_dio.options.baseUrl}$encryptedPath");
    debugPrint("data: $data");
    dynamic requestData = data;
    if (data != null && data is! FormData) {
      final plainTextJson = jsonEncode(data);
      final encryptedString = encryptPayload(plainTextJson);
      requestData = {'data': encryptedString};
    }
    final response = await _dio.put(encryptedPath, data: requestData);
    _decryptResponse(response);
    return response;
  }

  Future<Response> delete(String path, {dynamic data}) async {
    final encryptedPath = _encryptPathSegments(path);
    debugPrint("Full URL: ${_dio.options.baseUrl}$encryptedPath");
    debugPrint("data: $data");
    dynamic requestData = data;
    if (data != null && data is! FormData) {
      final plainTextJson = jsonEncode(data);
      final encryptedString = encryptPayload(plainTextJson);
      requestData = {'data': encryptedString};
    }
    final response = await _dio.delete(encryptedPath, data: requestData);
    _decryptResponse(response);
    return response;
  }
}

final apiClientProvider = Provider<ApiService>((ref) => ApiService(ref.read(dioProvider)));