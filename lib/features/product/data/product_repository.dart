import 'package:air_water/features/product/data/product_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
}