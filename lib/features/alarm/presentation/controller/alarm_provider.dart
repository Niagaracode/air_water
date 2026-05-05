import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/http/api_service.dart';
import '../../data/api/alarm_api.dart';
import '../model/alarm_model.dart';

class AlarmState {
  final bool isLoading;
  final List<Alarm> alarms;
  final String? error;

  AlarmState({
    this.isLoading = false,
    this.alarms = const [],
    this.error,
  });

  AlarmState copyWith({
    bool? isLoading,
    List<Alarm>? alarms,
    String? error,
  }) {
    return AlarmState(
      isLoading: isLoading ?? this.isLoading,
      alarms: alarms ?? this.alarms,
      error: error ?? this.error,
    );
  }
}

final alarmApiProvider = Provider<AlarmApi>((ref) {
  return AlarmApi(ref.read(apiClientProvider));
});

class AlarmNotifier extends Notifier<AlarmState> {
  @override
  AlarmState build() {
    return AlarmState();
  }

  Future<void> loadAlarms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final alarmApi = ref.read(alarmApiProvider);
      final response = await alarmApi.getAlarms(limit: 100);
      
      state = state.copyWith(isLoading: false, alarms: response.data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, AlarmState>(() => AlarmNotifier());
