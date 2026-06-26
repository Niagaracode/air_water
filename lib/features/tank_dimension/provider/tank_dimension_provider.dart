import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/http/api_service.dart';
import '../data/tank_dimension_api.dart';
import '../data/tank_dimension_model.dart';
import '../data/tank_dimension_repository.dart';
import '../data/tank_dimension_repository_impl.dart';

/// API PROVIDER
final tankDimensionApiProvider = Provider<TankDimensionApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return TankDimensionApi(client);
});

/// REPOSITORY PROVIDER
final tankDimensionRepoProvider = Provider<TankDimensionRepository>((ref) {
  return TankDimensionRepositoryImpl(ref.watch(tankDimensionApiProvider));
});

/// STATE NOTIFIER PROVIDER
final tankDimensionNotifierProvider =
StateNotifierProvider<TankDimensionNotifier, TankDimensionState>((ref) {
  return TankDimensionNotifier(ref.watch(tankDimensionRepoProvider));
});

/// TANK DIMENSION STATE
class TankDimensionState {
  final List<TankDimension> tankDimensions;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const TankDimensionState({
    required this.tankDimensions,
    required this.isLoading,
    this.isSaving = false,
    this.error,
  });

  TankDimensionState copyWith({
    List<TankDimension>? tankDimensions,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return TankDimensionState(
      tankDimensions: tankDimensions ?? this.tankDimensions,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// TANK DIMENSION NOTIFIER
class TankDimensionNotifier extends StateNotifier<TankDimensionState> {
  final TankDimensionRepository _repo;

  TankDimensionNotifier(this._repo) : super(
    const TankDimensionState(
      tankDimensions: [],
      isLoading: false,
    ),
  ) {
    loadTankDimensions();
  }

  /// LOAD TANK DIMENSIONS
  Future<void> loadTankDimensions() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final list = await _repo.getTankDimensions();

      if (!mounted) return;

      state = state.copyWith(
        tankDimensions: list,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// CREATE TANK DIMENSION
  Future<bool> createTankDimension(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(
        isSaving: true,
        error: null,
      );
      final item = await _repo.createTankDimension(data);
      if (!mounted) return false;
      final updatedList = [
        item,
        ...state.tankDimensions,
      ];
      state = state.copyWith(
        tankDimensions: updatedList,
        isSaving: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// UPDATE TANK DIMENSION
  Future<bool> updateTankDimension(int id, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(
        isSaving: true,
        error: null,
      );
      final updatedItem = await _repo.updateTankDimension(id, data);
      if (!mounted) return false;
      final updatedList = state.tankDimensions.map((item) {
        if (item.id == id) {
          return updatedItem;
        }
        return item;
      }).toList();
      state = state.copyWith(
        tankDimensions: updatedList,
        isSaving: false,
      );

      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// DELETE TANK DIMENSION
  Future<bool> deleteTankDimension(int id) async {
    try {
      final oldList = state.tankDimensions;
      /// Optimistic update
      final updatedList = oldList.where((item) {
        return item.id != id;
      }).toList();
      state = state.copyWith(tankDimensions: updatedList);
      await _repo.deleteTankDimension(id);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
