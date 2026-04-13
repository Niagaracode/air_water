import '../../domain/repository/group_repository.dart';
import '../api/group_api.dart';
import '../../presentation/model/group_model.dart';
import '../../../site/presentation/model/site_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupApi _api;

  GroupRepositoryImpl(this._api);

  @override
  Future<GroupPaginatedResponse> getGroups({
    int? companyId,
    String? name,
    int? status,
    int page = 1,
    int limit = 50,
  }) {
    return _api.getGroups(
      companyId: companyId,
      name: name,
      status: status,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Group> getGroupById(int id) {
    return _api.getGroupById(id);
  }

  @override
  Future<void> createGroup(GroupCreateRequest request) {
    return _api.createGroup(request);
  }

  @override
  Future<void> updateGroup(int id, Map<String, dynamic> data) {
    return _api.updateGroup(id, data);
  }

  @override
  Future<void> deleteGroup(int id) {
    return _api.deleteGroup(id);
  }

  @override
  Future<void> assignUsersToGroup(int groupId, List<int> userIds) {
    return _api.assignUsersToGroup(groupId, userIds);
  }

  @override
  Future<List<GroupUser>> getGroupUsers(int groupId) {
    return _api.getGroupUsers(groupId);
  }

  @override
  Future<List<Group>> getGroupsByUserId(int userId) {
    return _api.getGroupsByUserId(userId);
  }

  @override
  Future<void> assignGroupsToUser(int userId, List<int> groupIds) {
    return _api.assignGroupsToUser(userId, groupIds);
  }

  @override
  Future<void> removeUserFromGroup(int groupId, int userId) {
    return _api.removeUserFromGroup(groupId, userId);
  }

  @override
  Future<List<SiteUserCount>> getSitesWithUserCounts({String? name}) {
    return _api.getSitesWithUserCounts(name: name);
  }

  @override
  Future<SiteGroupDetails> getSiteGroupDetails(int siteId) {
    return _api.getSiteGroupDetails(siteId);
  }

  @override
  Future<List<SiteAutocompleteInfo>> getSiteSuggestions(String query) {
    return _api.getSiteSuggestions(query);
  }

  @override
  Future<void> unassignUserFromTank(int userId, int siteId, int tankId) {
    return _api.unassignUserFromTank(userId, siteId, tankId);
  }
}

