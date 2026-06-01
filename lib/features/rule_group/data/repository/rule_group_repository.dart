import '../../model/rule_group_model.dart';

abstract class RuleGroupRepository {

  Future<RuleGroupResponse> getRuleGroup({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    int? isActive,
  });

  Future<void> createRuleGroup(Map<String, dynamic> data);
  Future<void> updateRuleGroup(int id, Map<String, dynamic> data);
  Future<void> deleteRuleGroup(int id);

}