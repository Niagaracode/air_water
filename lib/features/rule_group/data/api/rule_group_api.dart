import '../../../../core/network/http/api_service.dart';
import '../../model/rule_group_model.dart';

class RuleGroupApi {
  final ApiService _client;

  RuleGroupApi(this._client);

  Future<RuleGroupResponse> getRuleGroup({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    int? isActive,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (isActive != null) {
      query['is_active'] = isActive;
    }

    final response = await _client.get('/rule-group', query: query);
    return RuleGroupResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }


  Future<void> createRuleGroup(Map<String, dynamic> data) async {
    await _client.post('/rule-group', data: data);
  }

  Future<void> updateRuleGroup(int id, Map<String, dynamic> data) async {
    await _client.put('/rule-group/$id', data: data);
  }

  Future<void> deleteRuleGroup(int id) async {
    await _client.delete('/rule-group/$id');
  }

}