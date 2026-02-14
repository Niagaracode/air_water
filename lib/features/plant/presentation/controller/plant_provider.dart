import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/plant_model.dart';
import '../../data/api/plant_api.dart';
import '../../domain/repository/plant_repository.dart';
import '../../data/repository/plant_repository_impl.dart';
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
  final bool isProcessing;
  final bool hasMore;
  final int page;
  final int totalEntries;
  final String? error;
  final String searchName;
  final int? selectedStatus;
  final String? selectedDate;

  PlantState({
    required this.plants,
    this.groupedPlants = const [],
    this.expandedGroups = const {},
    this.isLoading = false,
    this.isProcessing = false,
    this.hasMore = true,
    this.page = 1,
    this.totalEntries = 0,
    this.error,
    this.searchName = '',
    this.selectedStatus,
    this.selectedDate,
  });

  PlantState copyWith({
    List<Plant>? plants,
    List<PlantGroup>? groupedPlants,
    Set<String>? expandedGroups,
    bool? isLoading,
    bool? isProcessing,
    bool? hasMore,
    int? page,
    int? totalEntries,
    String? error,
    String? searchName,
    int? selectedStatus,
    String? selectedDate,
    bool clearStatus = false,
    bool clearDate = false,
  }) {
    return PlantState(
      plants: plants ?? this.plants,
      groupedPlants: groupedPlants ?? this.groupedPlants,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalEntries: totalEntries ?? this.totalEntries,
      error: error ?? this.error,
      searchName: searchName ?? this.searchName,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
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

  Future<void> loadGroupedPlants() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(plantRepositoryProvider);
      final response = await repository.getPlantsGrouped(
        page: 1,
        limit: _limit,
        name: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );

      final expandedGroups = <String>{};
      if (response.data.isNotEmpty) {
        expandedGroups.add(response.data.first.plantOrganizationCode!);
      }

      state = state.copyWith(
        groupedPlants: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
        totalEntries: response.pagination.total,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreGrouped() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(plantRepositoryProvider);
      final response = await repository.getPlantsGrouped(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
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

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
    loadGroupedPlants();
  }

  void setStatus(int? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
    loadGroupedPlants();
  }

  void setDate(String? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(selectedDate: date);
    }
    loadGroupedPlants();
  }

  void toggleGroup(String orgCode) {
    final expanded = Set<String>.from(state.expandedGroups);
    if (expanded.contains(orgCode)) {
      expanded.clear();
    } else {
      expanded.clear();
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
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(plantRepositoryProvider);
      await repository.createPlant(request);
      await loadGroupedPlants();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updatePlant(int id, PlantCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(plantRepositoryProvider);
      await repository.updatePlant(id, request);
      await loadGroupedPlants();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deletePlant(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(plantRepositoryProvider);
      await repository.deletePlant(id);
      await loadGroupedPlants();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final plantNotifierProvider = NotifierProvider<PlantNotifier, PlantState>(
  PlantNotifier.new,
);
