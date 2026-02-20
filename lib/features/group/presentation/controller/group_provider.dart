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
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;
  final int? filterCompanyId;
  final String? filterName;
  final int? filterStatus;
  final int totalEntries;
  final List<PlantUserCount> plantUserCounts;

  GroupState({
    this.groups = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filterCompanyId,
    this.filterName,
    this.filterStatus,
    this.totalEntries = 0,
    this.plantUserCounts = const [],
  });

  GroupState copyWith({
    List<Group>? groups,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    int? filterCompanyId,
    String? filterName,
    int? filterStatus,
    int? totalEntries,
    List<PlantUserCount>? plantUserCounts,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCompanyId: filterCompanyId ?? this.filterCompanyId,
      filterName: filterName ?? this.filterName,
      filterStatus: filterStatus ?? this.filterStatus,
      totalEntries: totalEntries ?? this.totalEntries,
      plantUserCounts: plantUserCounts ?? this.plantUserCounts,
    );
  }
}

class GroupNotifier extends Notifier<GroupState> {
  @override
  GroupState build() {
    ref.keepAlive();
    Future.microtask(() => loadPlantUserCounts());
    return GroupState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = state.copyWith(searchQuery: '', filterStatus: null);
    loadPlantUserCounts();
  }

  Future<void> loadGroups({
    int? companyId,
    String? name,
    int? status,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (!state.hasMore || state.isLoadingMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    } else {
      state = state.copyWith(
        isLoading: true,
        error: null,
        page: 1,
        hasMore: true,
      );
    }

    try {
      final repository = ref.read(groupRepositoryProvider);
      final currentPage = loadMore ? state.page + 1 : 1;

      final response = await repository.getGroups(
        companyId: companyId,
        name: name,
        status: status,
        page: currentPage,
        limit: 50,
      );

      final newGroups = response.groups;
      final hasMore = newGroups.length >= 50; // Assuming limit is 50

      if (loadMore) {
        state = state.copyWith(
          isLoadingMore: false,
          groups: [...state.groups, ...newGroups],
          page: currentPage,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          groups: newGroups,
          page: currentPage,
          hasMore: hasMore,
        );
      }
    } catch (e) {
      if (loadMore) {
        state = state.copyWith(isLoadingMore: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadPlantUserCounts({String? name}) async {
    final searchName = name ?? state.searchQuery;
    state = state.copyWith(
      isLoading: true,
      error: null,
      filterName: searchName,
    );
    try {
      final repository = ref.read(groupRepositoryProvider);
      final response = await repository.getPlantsWithUserCounts(
        name: searchName,
      );
      state = state.copyWith(
        isLoading: false,
        plantUserCounts: response,
        totalEntries: response.length,
      );
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

  Future<bool> removeUserFromGroup(int groupId, int userId) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(groupRepositoryProvider);
      await repository.removeUserFromGroup(groupId, userId);
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
