import 'package:air_water/features/rule_group/data/repository/rule_group_repository.dart';
import '../../model/rule_group_model.dart';
import '../api/rule_group_api.dart';

class RuleGroupRepositoryImpl implements RuleGroupRepository {
  final RuleGroupApi _api;

  RuleGroupRepositoryImpl(this._api);

  @override
  Future<RuleGroupResponse> getRuleGroup({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    int? isActive,
  }) {
    return _api.getRuleGroup(
      page: page,
      limit: limit,
      name: name,
      status: status,
      isActive: isActive,
    );
  }


  @override
  Future<void> createRuleGroup(Map<String, dynamic> data) {
    return _api.createRuleGroup(data);
  }

  @override
  Future<void> updateRuleGroup(int id, Map<String, dynamic> data) {
    return _api.updateRuleGroup(id, data);
  }

  @override
  Future<void> deleteRuleGroup(int id) {
    return _api.deleteRuleGroup(id);
  }

}