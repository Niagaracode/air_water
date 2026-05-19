import 'package:air_water/features/tank/data/tank_repository.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/tank_reading_model.dart';


class TankReadingParams {

  final int tankId;
  final String day;

  const TankReadingParams({
    required this.tankId,
    required this.day,
  });

  @override
  bool operator ==(Object other) {
    return other is TankReadingParams &&
        other.tankId == tankId &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(
    tankId,
    day,
  );
}

final tankReadingsProvider = StateNotifierProvider.family<
    TankReadingsNotifier,
    TankReadingsState,
    TankReadingParams>((ref, params) {

  return TankReadingsNotifier(
    ref.read(tankRepositoryProvider),
    params.tankId,
    params.day,
  );
});


class TankReadingsState {
  final bool isLoading;
  final List<TankReadingModel> readings;
  final String? error;

  const TankReadingsState({
    this.isLoading = false,
    this.readings = const [],
    this.error,
  });

  TankReadingsState copyWith({
    bool? isLoading,
    List<TankReadingModel>? readings,
    String? error,
  }) {
    return TankReadingsState(
      isLoading: isLoading ?? this.isLoading,
      readings: readings ?? this.readings,
      error: error,
    );
  }
}

class TankReadingsNotifier extends StateNotifier<TankReadingsState> {

  final TankRepository repository;
  final int tankId;
  final String day;

  TankReadingsNotifier(
      this.repository,
      this.tankId,
      this.day,
      ) : super(const TankReadingsState()) {

    loadReadings();
  }

  Future<void> loadReadings() async {

    try {

      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final response =
      await repository.getTankReadings(
        tankId,
        day,
      );

      final data = response['data'] as List;

      final readings = data
          .map((e) => TankReadingModel.fromJson(e))
          .toList();

      state = state.copyWith(
        isLoading: false,
        readings: readings,
      );

    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}