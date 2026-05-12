import '../../../core/network/http/api_service.dart';
import 'product_model.dart';

class ProductApi {

  final ApiService _client;
  ProductApi(this._client);

  /// GET PRODUCTS
  Future<List<Product>> getProducts() async {
    final res = await _client.get('/products');
    final map = res.data as Map<String, dynamic>;
    final list = map['data'] as List<dynamic>;
    return list.map((e) => Product.fromJson(e)).toList();
  }

  /// CREATE PRODUCT
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final res = await _client.post('/products', data: data);
    final response = res.data['data'];
    return Product.fromJson(response);
  }

  /// UPDATE PRODUCT
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _client.put('/products/$id', data: data);
    final response = res.data['data'];
    return Product.fromJson(response);
  }

  /// DELETE PRODUCT
  Future<void> deleteProduct(int id) async {
    await _client.delete('/products/$id');
  }
}