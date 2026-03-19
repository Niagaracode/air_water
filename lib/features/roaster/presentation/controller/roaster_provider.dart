import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/domain/repository/roaster_repository.dart';
import 'package:air_water/features/roaster/data/api/roaster_api.dart';
import 'package:air_water/features/roaster/data/repository/roaster_repository_impl.dart';
import 'package:air_water/core/network/api_client.dart';

class RoasterState {
  final List<Roaster> roasters;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final int totalEntries;
  final String searchName;
  final int? filterPlantId;
  final RoasterWithAssignments? selectedRoaster;

  RoasterState({
    this.roasters = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.totalEntries = 0,
    this.searchName = '',
    this.filterPlantId,
    this.selectedRoaster,
  });

  RoasterState copyWith({
    List<Roaster>? roasters,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    int? totalEntries,
    String? searchName,
    int? filterPlantId,
    RoasterWithAssignments? selectedRoaster,
  }) {
    return RoasterState(
      roasters: roasters ?? this.roasters,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
      searchName: searchName ?? this.searchName,
      filterPlantId: filterPlantId ?? this.filterPlantId,
      selectedRoaster: selectedRoaster ?? this.selectedRoaster,
    );
  }
}

class RoasterNotifier extends Notifier<RoasterState> {
  static const int _limit = 50;

  @override
  RoasterState build() {
    ref.keepAlive();
    Future.microtask(() => loadRoasters());
    return RoasterState();
  }

  Future<void> loadRoasters({bool isReload = false}) async {
    if (state.roasters.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, page: 1, roasters: []);
    }

    try {
      final repository = ref.read(roasterRepositoryProvider);
      final response = await repository.getRoasters(
        page: 1,
        limit: _limit,
        name: state.searchName,
        plantId: state.filterPlantId,
      );

      state = state.copyWith(
        roasters: response.data,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    try {
      final repository = ref.read(roasterRepositoryProvider);
      final response = await repository.getRoasters(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
        plantId: state.filterPlantId,
      );

      state = state.copyWith(
        roasters: [...state.roasters, ...response.data],
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
    loadRoasters(isReload: true);
  }

  Future<void> selectRoaster(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      final roasterData = await repository.getRoasterById(id);
      state = state.copyWith(selectedRoaster: roasterData, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
    }
  }

  Future<bool> createRoaster(Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.createRoaster(data);
      state = state.copyWith(isProcessing: false);
      await loadRoasters(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateRoaster(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.updateRoaster(id, data);
      state = state.copyWith(isProcessing: false);
      await loadRoasters(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignParameters({
    required int roasterId,
    required List<Map<String, dynamic>> assignments,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.manageAssignments(
        roasterId: roasterId,
        assignments: assignments,
      );
      state = state.copyWith(isProcessing: false);
      await selectRoaster(roasterId); 
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRoaster(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.deleteRoaster(id);
      state = state.copyWith(isProcessing: false);
      await loadRoasters(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final roasterApiProvider = Provider<RosterApi>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return RosterApi(apiClient);
});

final roasterRepositoryProvider = Provider<RoasterRepository>((ref) {
  final api = ref.read(roasterApiProvider);
  return RoasterRepositoryImpl(api);
});

final roasterNotifierProvider = NotifierProvider<RoasterNotifier, RoasterState>(() {
  return RoasterNotifier();
});
