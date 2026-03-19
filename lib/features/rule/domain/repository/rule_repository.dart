import '../../presentation/model/rule_model.dart';

abstract class RuleRepository {
  Future<RuleResponse> getRules({
    int page = 1,
    int limit = 10,
    String? name,
    String? parameterType,
    int? isActive,
    int? companyId,
  });

  Future<RuleGroupResponse> getRulesGrouped({
    int page = 1,
    int limit = 10,
    String? name,
    String? parameterType,
    int? isActive,
    int? companyId,
    int? plantId,
  });

  Future<List<RuleAutocompleteInfo>> searchRules({
    String? q,
  });

  Future<void> createRule(Map<String, dynamic> data);

  Future<void> updateRule(int id, Map<String, dynamic> data);

  Future<void> deleteRule(int id);

  Future<Rule?> getRuleById(int id);
}
