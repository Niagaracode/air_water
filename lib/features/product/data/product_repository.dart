import 'package:air_water/features/product/data/product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<void> updateProduct(int id, Map<String, dynamic> data);
  Future<int> createProduct(Map<String, dynamic> data);
}