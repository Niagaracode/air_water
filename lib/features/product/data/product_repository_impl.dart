import 'package:air_water/features/product/data/product_api.dart';
import 'package:air_water/features/product/data/product_model.dart';
import 'package:air_water/features/product/data/product_repository.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductApi _api;

  ProductRepositoryImpl(this._api);

  @override
  Future<List<Product>> getProducts() async {

    try {
      final list = await _api.getProducts();
      return list.map((e) => Product.fromJson(e)).toList();

    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : null;

      if (status == 404) {
        throw AppException(message ?? 'Products not found');
      }

      throw AppException(message ?? 'Failed to load products');
    }
  }

  @override
  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateProduct(id, data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to update product';
      throw AppException(message);
    }
  }

  @override
  Future<int> createProduct(Map<String, dynamic> data) async {
    try {
      return await _api.createProduct(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to create product';
      throw AppException(message);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final response = await _api.deleteProduct(id);
      if (response['statuscode'] != 200) {
        throw AppException(response['message'] ?? 'Failed to delete product');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to delete product';
      throw AppException(message);
    }
  }
}