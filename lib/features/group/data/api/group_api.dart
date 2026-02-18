import '../../../../core/network/api_client.dart';
import '../../presentation/model/group_model.dart';

class GroupApi {
  final ApiClient _client;

  GroupApi(this._client);

  Future<List<Group>> getGroups({
    int? companyId,
    String? name,
    int? status,
  }) async {
    final Map<String, dynamic> query = {};
    if (companyId != null) query['company_id'] = companyId;
    if (name != null) query['name'] = name;
    if (status != null) query['status'] = status;

    final response = await _client.get('/groups', query: query);
    return (response.data['data'] as List)
        .map((i) => Group.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<Group> getGroupById(int id) async {
    final response = await _client.get('/groups/$id');
    return Group.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> createGroup(GroupCreateRequest request) async {
    await _client.post('/groups', data: request.toJson());
  }

  Future<void> updateGroup(int id, Map<String, dynamic> data) async {
    await _client.put('/groups/$id', data: data);
  }

  Future<void> deleteGroup(int id) async {
    await _client.delete('/groups/$id');
  }

  Future<void> assignUsersToGroup(int groupId, List<int> userIds) async {
    await _client.post('/groups/$groupId/users', data: {'user_ids': userIds});
  }

  Future<List<GroupUser>> getGroupUsers(int groupId) async {
    final response = await _client.get('/groups/$groupId/users');
    return (response.data['data'] as List)
        .map((i) => GroupUser.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<Group>> getGroupsByUserId(int userId) async {
    final response = await _client.get('/groups/user/$userId');
    return (response.data['data'] as List)
        .map((i) => Group.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> assignGroupsToUser(int userId, List<int> groupIds) async {
    await _client.post('/groups/user/$userId', data: {'group_ids': groupIds});
  }
}
