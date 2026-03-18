import '../../domain/repository/rule_repository.dart';
import '../../presentation/model/rule_model.dart';
import '../api/rule_api.dart';

class RuleRepositoryImpl implements RuleRepository {
  final RuleApi _api;

  RuleRepositoryImpl(this._api);

  @override
  Future<RuleResponse> getRules({
    int page = 1,
    int limit = 10,
    String? name,
    String? parameterType,
    int? isActive,
    int? companyId,
  }) {
    return _api.getRules(
      page: page,
      limit: limit,
      name: name,
      parameterType: parameterType,
      isActive: isActive,
      companyId: companyId,
    );
  }

  @override
  Future<List<RuleAutocompleteInfo>> searchRules({String? q}) {
    return _api.searchRules(q: q);
  }

  @override
  Future<void> createRule(Map<String, dynamic> data) {
    return _api.createRule(data);
  }

  @override
  Future<void> updateRule(int id, Map<String, dynamic> data) {
    return _api.updateRule(id, data);
  }

  @override
  Future<void> deleteRule(int id) {
    return _api.deleteRule(id);
  }

  @override
  Future<Rule?> getRuleById(int id) {
    return _api.getRuleById(id);
  }
}
