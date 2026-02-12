import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/plant_model.dart';
import '../data/api/plant_api.dart';
import '../data/repository/plant_repository.dart';
import '../data/repository/plant_repository_impl.dart';
import '../../../../core/network/api_client.dart';

final plantApiProvider = Provider(
  (ref) => PlantApi(ref.read(apiClientProvider)),
);

final plantRepositoryProvider = Provider<PlantRepository>(
  (ref) => PlantRepositoryImpl(ref.read(plantApiProvider)),
);

class PlantState {
  final List<Plant> plants;
  final List<PlantGroup> groupedPlants;
  final Set<String> expandedGroups;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final int totalEntries;
  final String? error;

  PlantState({
    required this.plants,
    this.groupedPlants = const [],
    this.expandedGroups = const {},
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.totalEntries = 0,
    this.error,
  });

  PlantState copyWith({
    List<Plant>? plants,
    List<PlantGroup>? groupedPlants,
    Set<String>? expandedGroups,
    bool? isLoading,
    bool? hasMore,
    int? page,
    int? totalEntries,
    String? error,
  }) {
    return PlantState(
      plants: plants ?? this.plants,
      groupedPlants: groupedPlants ?? this.groupedPlants,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalEntries: totalEntries ?? this.totalEntries,
      error: error ?? this.error,
    );
  }
}

class PlantNotifier extends Notifier<PlantState> {
  static const int _limit = 50;

  @override
  PlantState build() {
    Future.microtask(() => loadGroupedPlants());
    return PlantState(plants: []);
  }

  Future<void> loadGroupedPlants({String? name, String? companyId}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(plantRepositoryProvider);
      final response = await repository.getPlantsGrouped(
        page: 1,
        limit: _limit,
        name: name,
        companyId: companyId,
      );
      state = state.copyWith(
        groupedPlants: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
        totalEntries: response.pagination.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreGrouped({String? name, String? companyId}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(plantRepositoryProvider);
      final response = await repository.getPlantsGrouped(
        page: nextPage,
        limit: _limit,
        name: name,
        companyId: companyId,
      );
      state = state.copyWith(
        groupedPlants: [...state.groupedPlants, ...response.data],
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleGroup(String orgCode) {
    final expanded = Set<String>.from(state.expandedGroups);
    if (expanded.contains(orgCode)) {
      expanded.remove(orgCode);
    } else {
      expanded.add(orgCode);
    }
    state = state.copyWith(expandedGroups: expanded);
  }

  Future<void> loadPlants({String? search}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(plantRepositoryProvider);
      final response = await repository.getPlants(
        page: 1,
        limit: _limit,
        search: search,
      );
      state = state.copyWith(
        plants: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? search}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(plantRepositoryProvider);
      final response = await repository.getPlants(
        page: nextPage,
        limit: _limit,
        search: search,
      );
      state = state.copyWith(
        plants: [...state.plants, ...response.data],
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPlant(PlantCreateRequest request) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(plantRepositoryProvider);
      await repository.createPlant(request);
      await loadGroupedPlants();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final plantNotifierProvider = NotifierProvider<PlantNotifier, PlantState>(
  PlantNotifier.new,
);
