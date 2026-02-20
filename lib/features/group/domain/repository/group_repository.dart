import '../../presentation/model/group_model.dart';

abstract class GroupRepository {
  Future<GroupPaginatedResponse> getGroups({
    int? companyId,
    String? name,
    int? status,
    int page = 1,
    int limit = 50,
  });
  Future<Group> getGroupById(int id);
  Future<void> createGroup(GroupCreateRequest request);
  Future<void> updateGroup(int id, Map<String, dynamic> data);
  Future<void> deleteGroup(int id);
  Future<void> assignUsersToGroup(int groupId, List<int> userIds);
  Future<List<GroupUser>> getGroupUsers(int groupId);
  Future<List<Group>> getGroupsByUserId(int userId);
  Future<void> assignGroupsToUser(int userId, List<int> groupIds);
  Future<void> removeUserFromGroup(int groupId, int userId);
  Future<List<PlantUserCount>> getPlantsWithUserCounts({String? name});
}
