import 'package:air_water/core/network/api_client.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';

class RosterApi {
  final ApiClient _client;

  RosterApi(this._client);

  Future<RoasterResponse> getRoasters({
    int page = 1,
    int limit = 10,
    String? name,
    int? plantId,
  }) async {
    final query = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (name != null && name.isNotEmpty) 'name': name,
      if (plantId != null) 'plant_id': plantId.toString(),
    };

    final response = await _client.get('/api/roster', query: query);
    return RoasterResponse.fromJson(response.data);
  }

  Future<RoasterWithAssignments> getRoasterById(int id) async {
    final response = await _client.get('/api/roster/$id');
    return RoasterWithAssignments.fromJson(response.data['data']);
  }

  Future<void> createRoaster(Map<String, dynamic> data) async {
    await _client.post('/api/roster', data: data);
  }

  Future<void> updateRoaster(int id, Map<String, dynamic> data) async {
    await _client.put('/api/roster/$id', data: data);
  }

  Future<void> deleteRoaster(int id) async {
    await _client.delete('/api/roster/$id');
  }

  Future<void> assignParameters({
    required int roasterId,
    required List<Map<String, dynamic>> assignments,
  }) async {
    await _client.post('/api/roster/assign-parameters', data: {
      'roaster_id': roasterId,
      'assignments': assignments,
    });
  }
}
