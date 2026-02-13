import '../../presentation/model/plant_model.dart';
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

    final response = await _client.get('/plants/grouped', query: query);
    return PlantResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<PlantGroupedResponse> getPlantsGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? companyId,
    int? status,
    String? date,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (companyId != null && companyId.isNotEmpty) {
      query['company_id'] = companyId;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }

    final response = await _client.get('/plants/grouped', query: query);
    return PlantGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> createPlant(PlantCreateRequest request) async {
    await _client.post('/plants', data: request.toJson());
  }
}
