import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/api/group_api.dart';
import '../../data/repository/group_repository_impl.dart';
import '../../domain/repository/group_repository.dart';
import '../model/group_model.dart';

class GroupState {
  final List<Group> groups;
  final bool isLoading;
  final bool isProcessing;
  final String? error;

  GroupState({
    this.groups = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
  });

  GroupState copyWith({
    List<Group>? groups,
    bool? isLoading,
    bool? isProcessing,
    String? error,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class GroupNotifier extends Notifier<GroupState> {
  @override
  GroupState build() {
    return GroupState();
  }

  Future<void> loadGroups({int? companyId, String? name, int? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      final groups = await repository.getGroups(
        companyId: companyId,
        name: name,
        status: status,
      );
      state = state.copyWith(isLoading: false, groups: groups);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createGroup(GroupCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.createGroup(request);
      state = state.copyWith(isProcessing: false);
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateGroup(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.updateGroup(id, data);
      state = state.copyWith(isProcessing: false);
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteGroup(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.deleteGroup(id);
      state = state.copyWith(isProcessing: false);
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignUsersToGroup(int groupId, List<int> userIds) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.assignUsersToGroup(groupId, userIds);
      state = state.copyWith(isProcessing: false);
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<GroupUser>> getGroupUsers(int groupId) async {
    try {
      final repository = ref.read(groupRepositoryProvider);
      return await repository.getGroupUsers(groupId);
    } catch (e) {
      return [];
    }
  }

  Future<List<Group>> getGroupsByUserId(int userId) async {
    try {
      final repository = ref.read(groupRepositoryProvider);
      return await repository.getGroupsByUserId(userId);
    } catch (e) {
      return [];
    }
  }

  Future<bool> assignGroupsToUser(int userId, List<int> groupIds) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.assignGroupsToUser(userId, groupIds);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final groupApiProvider = Provider<GroupApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return GroupApi(client);
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final api = ref.watch(groupApiProvider);
  return GroupRepositoryImpl(api);
});

final groupProvider = NotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);
