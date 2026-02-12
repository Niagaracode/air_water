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
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  PlantState({
    required this.plants,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  PlantState copyWith({
    List<Plant>? plants,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return PlantState(
      plants: plants ?? this.plants,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error ?? this.error,
    );
  }
}

class PlantNotifier extends Notifier<PlantState> {
  static const int _limit = 10;

  @override
  PlantState build() {
    // Trigger initial load
    Future.microtask(() => loadPlants());
    return PlantState(plants: []);
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
      await loadPlants();
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
