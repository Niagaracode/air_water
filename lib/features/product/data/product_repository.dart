import 'product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> createProduct(Map<String, dynamic> data);
  Future<Product> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
}