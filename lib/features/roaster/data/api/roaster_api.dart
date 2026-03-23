import '../../../../core/network/api_client.dart';
import '../../presentation/model/roaster_model.dart';

class RosterApi {
  final ApiClient _client;
  RosterApi(this._client);

  Future<RosterResponse> getRosters({int page = 1, int limit = 10, String? search}) async {
    final response = await _client.get(
      '/roster',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return RosterResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getRosterById(int id) async {
    final response = await _client.get('/roster/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> createRoster(Map<String, dynamic> data) async {
    await _client.post('/roster', data: data);
  }

  Future<void> updateRoster(int id, Map<String, dynamic> data) async {
    await _client.put('/roster/$id', data: data);
  }

  Future<void> deleteRoster(int id) async {
    await _client.delete('/roster/$id');
  }

  // Member Management
  Future<void> addMember(Map<String, dynamic> data) async {
    await _client.post('/roster/members', data: data);
  }

  Future<void> updateMember(int memberId, Map<String, dynamic> data) async {
    await _client.put('/roster/members/$memberId', data: data);
  }

  Future<void> removeMember(int memberId) async {
    await _client.delete('/roster/members/$memberId');
  }

  Future<List<RosterMember>> getRosterMembers(
    int rosterId, {
    String? q,
    int? roleId,
    int? status,
  }) async {
    final response = await _client.get(
      '/roster/$rosterId/members',
      query: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (roleId != null) 'roleId': roleId,
        if (status != null) 'status': status,
      },
    );
    return (response.data['data'] as List)
        .map((i) => RosterMember.fromJson(i as Map<String, dynamic>))
        .toList();
  }

}
