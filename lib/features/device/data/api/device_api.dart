import '../../../../core/network/api_client.dart';
import '../../presentation/model/device_model.dart';
import '../../../plant/presentation/model/plant_model.dart';

class DeviceApi {
  final ApiClient _client;

  DeviceApi(this._client);

  Future<DeviceGroupedResponse> getDevicesGrouped({
    int page = 1,
    int limit = 50,
    String? deviceId,
    String? plantName,
    String? searchQuery,
    int? siteId,
    int? companyId,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (deviceId != null && deviceId.isNotEmpty) {
      query['device_id'] = deviceId;
    }
    if (plantName != null && plantName.isNotEmpty) {
      query['plant_name'] = plantName;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query['q'] = searchQuery;
    }
    if (siteId != null) {
      query['site_id'] = siteId;
    }
    if (companyId != null) {
      query['company_id'] = companyId;
    }

    final response = await _client.get('/devices/grouped', query: query);
    return DeviceGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> createDevice(DeviceCreateRequest request) async {
    await _client.post('/devices', data: request.toJson());
  }

  Future<void> updateDevice(int id, DeviceCreateRequest request) async {
    await _client.put('/devices/$id', data: request.toJson());
  }

  Future<void> deleteDevice(int id) async {
    await _client.delete('/devices/$id');
  }

  Future<List<PlantAutocompleteInfo>> getPlantsForDeviceAutocomplete({
    String? q,
  }) async {
    final Map<String, dynamic> query = {};
    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }
    final response = await _client.get(
      '/plants/tank-autocomplete',
      query: query,
    );
    return (response.data['data'] as List)
        .map((i) => PlantAutocompleteInfo.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getDeviceDropdowns() async {
    final response = await _client.get('/devices/dropdowns');
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<List<String>> getDeviceNameSuggestions(String q) async {
    final Map<String, dynamic> query = {'q': q};
    final response = await _client.get(
      '/devices/autocomplete-names',
      query: query,
    );
    return List<String>.from(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> searchTanks(
    String q, {
    int? plantId,
  }) async {
    final Map<String, dynamic> query = {'q': q};
    if (plantId != null) {
      query['plant_id'] = plantId.toString();
    }
    final response = await _client.get('/tanks/autocomplete', query: query);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }
}
