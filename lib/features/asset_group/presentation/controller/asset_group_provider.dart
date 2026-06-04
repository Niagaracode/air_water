import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/http/api_service.dart';
import '../../domain/models/asset_group_model.dart';
import '../../../../features/user/presentation/controller/user_provider.dart';

class AssetGroupState {
  final List<AssetGroupModel> groups;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final AssetGroupModel? currentGroup;
  final List<dynamic> previewAssets;

  AssetGroupState({
    this.groups = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.currentGroup,
    this.previewAssets = const [],
  });

  AssetGroupState copyWith({
    List<AssetGroupModel>? groups,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    AssetGroupModel? currentGroup,
    List<dynamic>? previewAssets,
  }) {
    return AssetGroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      currentGroup: currentGroup ?? this.currentGroup,
      previewAssets: previewAssets ?? this.previewAssets,
    );
  }
}

class AssetGroupNotifier extends Notifier<AssetGroupState> {
  @override
  AssetGroupState build() {
    ref.keepAlive();
    
    // Listen to user changes to trigger reload when current user data becomes available
    ref.listen(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        loadGroups();
      }
    });

    // Initial load only if user is already available
    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser != null) {
      Future.microtask(() => loadGroups());
    }
    
    return AssetGroupState();
  }

  Future<void> loadGroups() async {
    // Auth Guard: Don't fetch if no user is logged in (prevents 401 during logout)
    if (ref.read(userProvider).currentUser == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/asset-groups', query: {'domain': 'AIRWATER'});

      final List<AssetGroupModel> groups = (response.data['data'] as List)
          .map((json) => AssetGroupModel.fromJson(json))
          .toList();

      state = state.copyWith(isLoading: false, groups: groups);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadGroupById(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/asset-groups/$id');

      final group = AssetGroupModel.fromJson(response.data['data']);
      state = state.copyWith(isProcessing: false, currentGroup: group);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<int?> saveGroupAndGetId(
    AssetGroupModel group, {
    List<AssetGroupUser>? users,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final data = group.toJson();
      if (users != null) {
        data['users'] = users.map((u) => u.toJson()).toList();
      }

      int? savedId;
      if (group.id != null) {
        await client.put('/asset-groups/${group.id}', data: data);
        savedId = group.id;
      } else {
        final response = await client.post('/asset-groups', data: data);
        savedId = response.data['id'] as int?;
      }

      state = state.copyWith(isProcessing: false);
      await loadGroups();
      // Reload users to update the counts in the manager list
      await ref.read(userProvider.notifier).loadUsers();
      return savedId;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.response?.data['error'] ?? e.message;
      state = state.copyWith(isProcessing: false, error: errorMessage.toString());
      return null;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return null;
    }
  }

  Future<bool> saveGroup(
    AssetGroupModel group, {
    List<AssetGroupUser>? users,
  }) async {
    final id = await saveGroupAndGetId(group, users: users);
    return id != null;
  }

  Future<void> loadPreview(int id) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/asset-groups/$id/preview');
      state = state.copyWith(previewAssets: response.data['data'] as List);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> deleteGroup(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/asset-groups/$id');
      state = state.copyWith(isProcessing: false);
      await loadGroups();
      return true;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.response?.data['error'] ?? e.message;
      state = state.copyWith(isProcessing: false, error: errorMessage.toString());
      return false;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<void> updateGroupStatus(int id, bool displayInTree) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/asset-groups/$id', data: {
        'display_in_tree': displayInTree ? 1 : 0,
      });
      await loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final assetGroupProvider =
    NotifierProvider<AssetGroupNotifier, AssetGroupState>(
      AssetGroupNotifier.new,
    );

class RosterGroupNotifier extends Notifier<AssetGroupState> {
  @override
  AssetGroupState build() {
    ref.keepAlive();
    
    // Listen to user changes to trigger reload when current user data becomes available
    ref.listen(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        loadGroups();
      }
    });

    // Initial load only if user is already available
    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser != null) {
      Future.microtask(() => loadGroups());
    }
    
    return AssetGroupState();
  }

  Future<void> loadGroups() async {
    if (ref.read(userProvider).currentUser == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/asset-groups', query: {'domain': 'ROSTER'});

      final List<AssetGroupModel> groups = (response.data['data'] as List)
          .map((json) => AssetGroupModel.fromJson(json))
          .toList();

      state = state.copyWith(isLoading: false, groups: groups);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final rosterGroupProvider =
    NotifierProvider<RosterGroupNotifier, AssetGroupState>(
      RosterGroupNotifier.new,
    );
