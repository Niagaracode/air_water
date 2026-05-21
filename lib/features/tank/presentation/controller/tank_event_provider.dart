import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/model/tank_event_model.dart';
import '../../data/tank_repository.dart';

class TankEventParams {
  final int tankId;
  final String day;

  const TankEventParams({
    required this.tankId,
    required this.day,
  });

  @override
  bool operator ==(Object other) {
    return other is TankEventParams &&
        other.tankId == tankId &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(tankId, day);
}

final tankEventsProvider = StateNotifierProvider.family<
    TankEventsNotifier,
    TankEventsState,
    TankEventParams>((ref, params) {

  return TankEventsNotifier(
    ref.read(tankRepositoryProvider),
    params.tankId,
    params.day,
  );
});

class TankEventsState {

  final bool isLoading;
  final List<TankEventModel> events;
  final String? error;

  const TankEventsState({
    this.isLoading = false,
    this.events = const [],
    this.error,
  });

  TankEventsState copyWith({
    bool? isLoading,
    List<TankEventModel>? events,
    String? error,
  }) {
    return TankEventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      error: error,
    );
  }
}

class TankEventsNotifier
    extends StateNotifier<TankEventsState> {

  final TankRepository repository;
  final int tankId;
  final String day;

  TankEventsNotifier(
      this.repository,
      this.tankId,
      this.day,
      ) : super(const TankEventsState()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final events = await repository.getTankEvents(tankId, day);
      state = state.copyWith(isLoading: false, events: events);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}