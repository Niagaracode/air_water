import 'package:air_water/features/tank/data/tank_repository.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/tank_reading_model.dart';

class TankReadingParams {
  final int tankId;
  final String? day;
  final DateTime? startDate;
  final DateTime? endDate;

  const TankReadingParams({
    required this.tankId,
    this.day,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    return other is TankReadingParams &&
        other.tankId == tankId &&
        other.day == day &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
    tankId,
    day,
    startDate,
    endDate,
  );
}

// autoDispose: when the Readings tab (and this provider's last listener)
// is disposed, the cached notifier + state are thrown away. Coming back to
// the tab creates a brand-new notifier, which fetches fresh data instead
// of reusing a stale snapshot from the first visit.
final tankReadingsProvider = StateNotifierProvider.family
    .autoDispose<TankReadingsNotifier, TankReadingsState, TankReadingParams>((
    ref,
    params,
    ) {
  return TankReadingsNotifier(
    ref.read(tankRepositoryProvider),
    params.tankId,
    params.day,
    params.startDate,
    params.endDate,
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
  final String? day;
  final DateTime? startDate;
  final DateTime? endDate;

  TankReadingsNotifier(
      this.repository,
      this.tankId,
      this.day,
      this.startDate,
      this.endDate,
      ) : super(const TankReadingsState()) {
    loadReadings();
  }

  Future<void> loadReadings() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final response = await repository.getTankReadings(
        tankId: tankId,
        day: day,
        startDate: startDate,
        endDate: endDate,
      );

      final data = response['data'] as List;

      final readings = data.map((e) => TankReadingModel.fromJson(e)).toList();

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