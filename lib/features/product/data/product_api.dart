import '../../../core/network/api_client.dart';

class ProductApi {
  final ApiClient _client;

  ProductApi(this._client);

  Future<List<dynamic>> getProducts() async {
    final res = await _client.get('/products');

    print('TYPE: ${res.data.runtimeType}');
    print('DATA: ${res.data}');

    final map = res.data as Map<String, dynamic>;
    return map['data'] as List<dynamic>;
  }
}