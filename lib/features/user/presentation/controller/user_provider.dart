import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../domain/repository/user_repository.dart';
import '../model/user_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../tank/presentation/model/tank_model.dart';

class UserState {
  final List<User> users;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final User? currentUser;

  UserState({
    required this.users,
    required this.isLoading,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    this.currentUser,
  });

  UserState copyWith({
    List<User>? users,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    User? currentUser,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    // Load current user when the provider is initialized
    _loadCurrentUser();
    return UserState(users: [], isLoading: false);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final repository = ref.read(userRepositoryProvider);
      final currentUser = await repository.getCurrentUser();
      state = state.copyWith(currentUser: currentUser);
    } catch (e) {
      // If we can't load current user, continue anyway
      debugPrint('Could not load current user: $e');
    }
  }

  Future<void> loadUsers({
    String? searchQuery,
    String? username,
    String? email,
    int? roleId,
    int? companyId,
    int? status,
    int? plantId,
    int? tankId,
  }) async {
    state = state.copyWith(isLoading: true, page: 1, users: []);
    try {
      final repository = ref.read(userRepositoryProvider);
      final response = await repository.searchUsers(
        page: 1,
        q: searchQuery,
        username: username,
        email: email,
        roleId: roleId,
        companyId: companyId,
        status: status,
        plantId: plantId,
        tankId: tankId,
      );

      // Filter out the current logged-in user
      final filteredUsers = state.currentUser != null
          ? response.data
                .where((user) => user.userId != state.currentUser!.userId)
                .toList()
          : response.data;

      state = state.copyWith(
        users: filteredUsers,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? searchQuery,
    String? username,
    String? email,
    int? roleId,
    int? companyId,
    int? status,
    int? plantId,
    int? tankId,
  }) async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(userRepositoryProvider);
      final response = await repository.searchUsers(
        page: nextPage,
        q: searchQuery,
        username: username,
        email: email,
        roleId: roleId,
        companyId: companyId,
        status: status,
        plantId: plantId,
        tankId: tankId,
      );

      // Filter out the current logged-in user
      final filteredNewUsers = state.currentUser != null
          ? response.data
                .where((user) => user.userId != state.currentUser!.userId)
                .toList()
          : response.data;

      final updatedUsers = [...state.users, ...filteredNewUsers];

      state = state.copyWith(
        users: updatedUsers,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createUser(UserCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.createUser(request);
      state = state.copyWith(isProcessing: false);
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateUser(int id, UserCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.updateUser(id, request);
      state = state.copyWith(isProcessing: false);
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.deleteUser(id);
      state = state.copyWith(isProcessing: false);
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<Role>> getRoles() async {
    try {
      final repository = ref.read(userRepositoryProvider);
      return await repository.getRoles();
    } catch (e) {
      return [];
    }
  }

  Future<List<CompanyAutocomplete>> searchCompanies(String query) async {
    try {
      final repository = ref.read(userRepositoryProvider);
      return await repository.searchCompanies(query);
    } catch (e) {
      return [];
    }
  }

  Future<List<PlantAutocompleteInfo>> searchPlants(String query) async {
    try {
      final repository = ref.read(userRepositoryProvider);
      return await repository.searchPlants(query);
    } catch (e) {
      return [];
    }
  }

  Future<TankGroupedResponse?> getTanksGrouped({
    int page = 1,
    int limit = 500, // Load many for selection
    String? plantName,
    String? tankName,
    int? status,
  }) async {
    try {
      final repository = ref.read(userRepositoryProvider);
      return await repository.getTanksGrouped(
        page: page,
        limit: limit,
        plantName: plantName,
        tankName: tankName,
        status: status,
      );
    } catch (e) {
      debugPrint('Error fetching grouped tanks: $e');
      return null;
    }
  }

  Future<List<String>> getUserNameSuggestions(String query) async {
    try {
      final repository = ref.read(userRepositoryProvider);
      return await repository.getUserNameSuggestions(query);
    } catch (e) {
      return [];
    }
  }
}

final userApiProvider = Provider<UserApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserApi(client);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final api = ref.watch(userApiProvider);
  return UserRepositoryImpl(api);
});

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
