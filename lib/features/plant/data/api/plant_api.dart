import '../../model/plant_model.dart';
import '../../../../core/network/api_client.dart';

class PlantApi {
  final ApiClient _client;

  PlantApi(this._client);

  Future<PlantResponse> getPlants({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await _client.get('/plants', query: query);
    return PlantResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> createPlant(PlantCreateRequest request) async {
    await _client.post('/plants', data: request.toJson());
  }
}
