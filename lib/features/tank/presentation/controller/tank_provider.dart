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
  final bool hasMore;
  final Set<String> expandedGroups;
  final List<TankProduct> products;

  TankState({
    required this.groupedTanks,
    required this.isLoading,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    required this.expandedGroups,
    this.products = const [],
  });

  TankState copyWith({
    List<TankGroup>? groupedTanks,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    Set<String>? expandedGroups,
    List<TankProduct>? products,
  }) {
    return TankState(
      groupedTanks: groupedTanks ?? this.groupedTanks,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      products: products ?? this.products,
    );
  }
}

class TankNotifier extends Notifier<TankState> {
  @override
  TankState build() {
    return TankState(groupedTanks: [], isLoading: false, expandedGroups: {});
  }

  Future<void> loadGroupedTanks({
    String? plantName,
    String? tankName,
    int? status,
  }) async {
    state = state.copyWith(isLoading: true, page: 1, groupedTanks: []);
    try {
      final repository = ref.read(tankRepositoryProvider);
      final response = await repository.getTanksGrouped(
        page: 1,
        plantName: plantName,
        tankName: tankName,
        status: status,
      );

      final expandedGroups = <String>{};
      for (var group in response.data) {
        expandedGroups.add(group.plantName);
      }

      state = state.copyWith(
        groupedTanks: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? plantName,
    String? tankName,
    int? status,
  }) async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(tankRepositoryProvider);
      final response = await repository.getTanksGrouped(
        page: nextPage,
        plantName: plantName,
        tankName: tankName,
        status: status,
      );

      final updatedGroups = [...state.groupedTanks, ...response.data];
      final expandedGroups = Set<String>.from(state.expandedGroups);
      for (var group in response.data) {
        expandedGroups.add(group.plantName);
      }

      state = state.copyWith(
        groupedTanks: updatedGroups,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTank(TankCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
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
    state = state.copyWith(isProcessing: true, error: null);
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
    state = state.copyWith(isProcessing: true, error: null);
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
