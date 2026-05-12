import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import 'product_api.dart';
import 'product_model.dart';
import 'product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {

  final ProductApi _api;
  ProductRepositoryImpl(this._api);

  @override
  Future<List<Product>> getProducts() async {
    try {
      return await _api.getProducts();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to load products';
      throw AppException(message);
    }
  }

  @override
  Future<Product> createProduct(Map<String, dynamic> data) async {
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
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      return await _api.updateProduct(id, data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to update product';
      throw AppException(message);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await _api.deleteProduct(id);
    } on DioException catch (e) {
      final data = e.response?.data;

      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to delete product';
      throw AppException(message);
    }
  }
}