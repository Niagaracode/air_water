import '../../../core/network/http/api_service.dart';

class ProductApi {
  final ApiService _client;

  ProductApi(this._client);

  Future<List<dynamic>> getProducts() async {
    final res = await _client.get('/products');

    final map = res.data as Map<String, dynamic>;
    return map['data'] as List<dynamic>;
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    await _client.put('/products/$id', data: data);
  }

  Future<int> createProduct(Map<String, dynamic> data) async {
    final res = await _client.post('/products', data: data);
    return res.data['data']['id'] as int;
  }

  Future<Map<String, dynamic>> deleteProduct(int id) async {
    final res = await _client.delete('/products/$id');
    return res.data;
  }
}