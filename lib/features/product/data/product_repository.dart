import 'package:air_water/features/product/data/product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<int> createProduct(Map<String, dynamic> data);
  Future<void> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
}