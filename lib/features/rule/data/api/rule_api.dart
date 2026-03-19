import '../../presentation/model/rule_model.dart';
import '../../../../core/network/api_client.dart';

class RuleApi {
  final ApiClient _client;

  RuleApi(this._client);

  Future<RuleResponse> getRules({
    int page = 1,
    int limit = 10,
    String? name,
    String? parameterType,
    int? isActive,
    int? companyId,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (parameterType != null && parameterType.isNotEmpty) {
      query['parameter_type'] = parameterType;
    }
    if (isActive != null) {
      query['is_active'] = isActive;
    }
    if (companyId != null) {
      query['company_id'] = companyId;
    }

    final response = await _client.get('/rules', query: query);
    return RuleResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<RuleGroupResponse> getRulesGrouped({
    int page = 1,
    int limit = 10,
    String? name,
    String? parameterType,
    int? isActive,
    int? companyId,
    int? plantId,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (parameterType != null && parameterType.isNotEmpty) {
      query['parameter_type'] = parameterType;
    }
    if (isActive != null) {
      query['is_active'] = isActive;
    }
    if (companyId != null) {
      query['company_id'] = companyId;
    }
    if (plantId != null) {
      query['plant_id'] = plantId;
    }

    final response = await _client.get('/rules/grouped', query: query);
    return RuleGroupResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<RuleAutocompleteInfo>> searchRules({
    String? q,
  }) async {
    final Map<String, dynamic> query = q != null ? {'q': q} : {};
    final response = await _client.get('/rules/search', query: query);
    final List data = response.data['data'] ?? [];
    return data
        .map(
          (e) => RuleAutocompleteInfo.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> createRule(Map<String, dynamic> data) async {
    await _client.post('/rules', data: data);
  }

  Future<void> updateRule(int id, Map<String, dynamic> data) async {
    await _client.put('/rules/$id', data: data);
  }

  Future<void> deleteRule(int id) async {
    await _client.delete('/rules/$id');
  }

  Future<Rule?> getRuleById(int id) async {
    final response = await _client.get('/rules/$id');
    if (response.data['data'] != null) {
      return Rule.fromJson(Map<String, dynamic>.from(response.data['data']));
    }
    return null;
  }
}
