import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/api/tank_api.dart';
import '../../data/repository/tank_repository_impl.dart';
import '../model/tank_model.dart';
import '../../../plant/presentation/model/plant_model.dart';

class TankState {
  final List<TankGroup> groupedTanks;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final int totalEntries;
  final bool hasMore;
  final Set<String> expandedGroups;
  final List<TankProduct> products;
  final String searchPlant;
  final String searchTank;
  final int? selectedStatus;

  TankState({
    required this.groupedTanks,
    required this.isLoading,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.totalEntries = 0,
    this.hasMore = false,
    required this.expandedGroups,
    this.products = const [],
    this.searchPlant = '',
    this.searchTank = '',
    this.selectedStatus,
  });

  TankState copyWith({
    List<TankGroup>? groupedTanks,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    int? totalEntries,
    bool? hasMore,
    Set<String>? expandedGroups,
    List<TankProduct>? products,
    String? searchPlant,
    String? searchTank,
    int? selectedStatus,
    bool clearError = false,
  }) {
    return TankState(
      groupedTanks: groupedTanks ?? this.groupedTanks,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalEntries: totalEntries ?? this.totalEntries,
      hasMore: hasMore ?? this.hasMore,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      products: products ?? this.products,
      searchPlant: searchPlant ?? this.searchPlant,
      searchTank: searchTank ?? this.searchTank,
      selectedStatus: selectedStatus != null
          ? selectedStatus
          : this.selectedStatus,
    );
  }
}

class TankNotifier extends Notifier<TankState> {
  @override
  TankState build() {
    ref.keepAlive();
    // Initial load will be handled by the UI or via Future.microtask
    Future.microtask(() => loadGroupedTanks());
    return TankState(groupedTanks: [], isLoading: false, expandedGroups: {});
  }

  void setSearchPlant(String value) {
    state = state.copyWith(searchPlant: value);
  }

  void setSearchTank(String value) {
    state = state.copyWith(searchTank: value);
  }

  void setStatus(int? value) {
    state = state.copyWith(selectedStatus: value);
    loadGroupedTanks();
  }

  void clearFilters() {
    state = state.copyWith(
      searchPlant: '',
      searchTank: '',
      selectedStatus: null,
    );
    loadGroupedTanks();
  }

  Future<void> loadGroupedTanks() async {
    state = state.copyWith(isLoading: true, page: 1, groupedTanks: []);
    try {
      final repository = ref.read(tankRepositoryProvider);
      final response = await repository.getTanksGrouped(
        page: 1,
        plantName: state.searchPlant.isEmpty ? null : state.searchPlant,
        tankName: state.searchTank.isEmpty ? null : state.searchTank,
        status: state.selectedStatus,
      );

      final expandedGroups = <String>{};
      for (var group in response.data) {
        expandedGroups.add(group.plantName);
      }

      state = state.copyWith(
        groupedTanks: response.data,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(tankRepositoryProvider);
      final response = await repository.getTanksGrouped(
        page: nextPage,
        plantName: state.searchPlant.isEmpty ? null : state.searchPlant,
        tankName: state.searchTank.isEmpty ? null : state.searchTank,
        status: state.selectedStatus,
      );

      final updatedGroups = [...state.groupedTanks, ...response.data];
      final expandedGroups = Set<String>.from(state.expandedGroups);
      for (var group in response.data) {
        expandedGroups.add(group.plantName);
      }

      state = state.copyWith(
        groupedTanks: updatedGroups,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTank(TankCreateRequest request) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.createTank(request);
      state = state.copyWith(isProcessing: false);
      await loadGroupedTanks();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateTank(int id, TankCreateRequest request) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.updateTank(id, request);
      state = state.copyWith(isProcessing: false);
      await loadGroupedTanks();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTank(int id) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.deleteTank(id);
      state = state.copyWith(isProcessing: false);
      await loadGroupedTanks();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<PlantAutocompleteInfo>> searchPlants(String query) async {
    try {
      final repository = ref.read(tankRepositoryProvider);
      return await repository.getPlantsForTankAutocomplete(q: query);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDropdowns() async {
    final repository = ref.read(tankRepositoryProvider);
    return await repository.getTankDropdowns();
  }

  Future<List<String>> getTankNameSuggestions(String query) async {
    try {
      final repository = ref.read(tankRepositoryProvider);
      return await repository.getTankNameSuggestions(q: query);
    } catch (e) {
      return [];
    }
  }

  Future<List<TankProduct>> getProducts() async {
    try {
      final repository = ref.read(tankRepositoryProvider);
      final products = await repository.getProducts();
      state = state.copyWith(products: products);
      return products;
    } catch (e) {
      return [];
    }
  }
}

final tankApiProvider = Provider<TankApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return TankApi(client);
});

final tankRepositoryProvider = Provider<TankRepository>((ref) {
  final api = ref.watch(tankApiProvider);
  return TankRepositoryImpl(api);
});

final tankProvider = NotifierProvider<TankNotifier, TankState>(
  TankNotifier.new,
);
