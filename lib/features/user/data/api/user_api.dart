import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../presentation/model/user_model.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../../tank/presentation/model/tank_model.dart';

class UserApi {
  final ApiClient _client;

  UserApi(this._client);

  Future<UserSearchResponse> searchUsers({
    int page = 1,
    int limit = 50,
    String? q,
    String? username,
    String? email,
    int? roleId,
    int? companyId,
    int? status,
    int? siteId,
    int? tankId,
    List<Map<String, dynamic>>? excludeAssignments,
    String? groupName,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};

    if (q != null && q.isNotEmpty) query['q'] = q;
    if (username != null && username.isNotEmpty) query['username'] = username;
    if (email != null && email.isNotEmpty) query['email'] = email;
    if (roleId != null) query['role_id'] = roleId;
    if (companyId != null) query['company_id'] = companyId;
    if (status != null) query['status'] = status;
    if (siteId != null) query['plant_id'] = siteId;
    if (tankId != null) query['tank_id'] = tankId;
    if (excludeAssignments != null && excludeAssignments.isNotEmpty) {
      query['exclude_assignments'] = jsonEncode(excludeAssignments);
    }
    if (groupName != null) query['group_name'] = groupName;

    final response = await _client.get('/users/search', query: query);
    return UserSearchResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<User>> getUsers({String? username, int? roleId}) async {
    final Map<String, dynamic> query = {};

    if (username != null && username.isNotEmpty) query['username'] = username;
    if (roleId != null) query['role_id'] = roleId;

    final response = await _client.get('/users', query: query);
    return (response.data['data'] as List)
        .map((i) => User.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser(UserCreateRequest request) async {
    await _client.post('/users', data: request.toJson());
  }

  Future<void> updateUser(int id, UserCreateRequest request) async {
    await _client.put('/users/$id', data: request.toJson());
  }

  Future<void> deleteUser(int id) async {
    await _client.delete('/users/$id');
  }

  Future<List<Role>> getRoles() async {
    final response = await _client.get('/roles');
    return (response.data['data'] as List)
        .map((i) => Role.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<CompanyAutocomplete>> searchCompanies(String q) async {
    final Map<String, dynamic> query = {'q': q};
    final response = await _client.get('/companies/autocomplete', query: query);
    return (response.data['data'] as List)
        .map((i) => CompanyAutocomplete.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<SiteAutocompleteInfo>> searchSites(String q) async {
    final Map<String, dynamic> query = {'q': q};
    final response = await _client.get(
      '/plants/tank-autocomplete',
      query: query,
    );
    return (response.data['data'] as List)
        .map((i) => SiteAutocompleteInfo.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? siteName,
    String? tankName,
    int? status,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (siteName != null && siteName.isNotEmpty) {
      query['plant_name'] = siteName;
    }
    if (tankName != null && tankName.isNotEmpty) {
      query['tank_number'] = tankName;
    }
    if (status != null) {
      query['status'] = status;
    }

    final response = await _client.get('/tanks/grouped', query: query);
    return TankGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<String>> getUserNameSuggestions(String q) async {
    final Map<String, dynamic> query = {'q': q};
    final response = await _client.get('/users/autocomplete', query: query);
    return (response.data['data'] as List)
        .map((i) => i['username'] as String)
        .toList();
  }

  Future<User> getCurrentUser() async {
    final response = await _client.get('/me');
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }
}
