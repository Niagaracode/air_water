import '../../../../core/network/http/api_service.dart';
import '../../presentation/model/setting_model.dart';

class SettingApi {
  final ApiService _client;

  SettingApi(this._client);

  Future<SettingGroupResponse> getSettingsGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? parameterType,
    int? plantId,
    int? tankId,
    int? isActive,
  }) async {
    final queryParameters = {
      'page': page,
      'limit': limit,
      if (name != null && name.isNotEmpty) 'name': name,
      if (parameterType != null) 'parameter_type': parameterType,
      if (plantId != null) 'plant_id': plantId,
      if (tankId != null) 'tank_id': tankId,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _client.get(
      '/rules/grouped',
      query: queryParameters,
    );

    return SettingGroupResponse.fromJson(response.data);
  }

  Future<SettingResponse> getSettings({
    int page = 1,
    int limit = 20,
    String? name,
    String? parameterType,
    int? plantId,
    int? tankId,
    int? isActive,
  }) async {
    final queryParameters = {
      'page': page,
      'limit': limit,
      if (name != null && name.isNotEmpty) 'name': name,
      if (parameterType != null) 'parameter_type': parameterType,
      if (plantId != null) 'plant_id': plantId,
      if (tankId != null) 'tank_id': tankId,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _client.get('/rules', query: queryParameters);
    return SettingResponse.fromJson(response.data);
  }

  Future<void> createSetting(Map<String, dynamic> data) async {
    await _client.post('/rules', data: data);
  }

  Future<void> updateSetting(int id, Map<String, dynamic> data) async {
    await _client.put('/rules/$id', data: data);
  }

  Future<void> deleteSetting(int id) async {
    await _client.delete('/rules/$id');
  }

  Future<List<SettingAutocompleteInfo>> searchSettings({String? q}) async {
    final response = await _client.get(
      '/rules/search',
      query: {if (q != null) 'q': q},
    );
    return (response.data['data'] as List)
        .map((e) => SettingAutocompleteInfo.fromJson(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTemplatesByParameter(
    String parameterType,
  ) async {
    final response = await _client.get(
      '/rules-templates/by-parameter',
      query: {'parameterType': parameterType},
    );
    return List<Map<String, dynamic>>.from(response.data['data'] as List);
  }
}
