import '../../presentation/model/group_model.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroups({int? companyId, String? name, int? status});
  Future<Group> getGroupById(int id);
  Future<void> createGroup(GroupCreateRequest request);
  Future<void> updateGroup(int id, Map<String, dynamic> data);
  Future<void> deleteGroup(int id);
  Future<void> assignUsersToGroup(int groupId, List<int> userIds);
  Future<List<GroupUser>> getGroupUsers(int groupId);
  Future<List<Group>> getGroupsByUserId(int userId);
  Future<void> assignGroupsToUser(int userId, List<int> groupIds);
}
