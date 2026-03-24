import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/alarm_model.dart';
import '../../../setting/data/api/setting_api.dart';
import '../../../../core/network/api_client.dart';

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

class AlarmNotifier extends Notifier<AlarmState> {
  @override
  AlarmState build() {
    return AlarmState();
  }

  Future<void> loadAlarms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settingApi = SettingApi(ref.read(apiClientProvider));
      final settingsResponse = await settingApi.getSettings(limit: 100, isActive: 1);
      
      final List<Alarm> triggeredAlarms = [];
      
      // 2. Add some more mock alarms based on existing settings or generic data
      if (settingsResponse.data.isNotEmpty) {
        for (var i = 0; i < settingsResponse.data.length && i < 5; i++) {
          final setting = settingsResponse.data[i];
          triggeredAlarms.add(Alarm(
            id: setting.id,
            ruleName: setting.name,
            plantName: setting.plantName ?? 'Global',
            tankNumber: setting.tankNumber ?? 'Generic',
            parameterType: setting.parameterType ?? 'Unknown',
            conditionType: setting.conditionType ?? 'GREATER THAN',
            threshold1: setting.threshold1 ?? 0,
            threshold2: setting.threshold2,
            currentValue: (setting.threshold1 ?? 0) + 15.0, // Mock current value being over threshold
            importance: setting.importance ?? 'Medium',
            triggeredAt: DateTime.now().subtract(Duration(hours: i + 1)),
            status: 'Active',
          ));
        }
      }

      state = state.copyWith(isLoading: false, alarms: triggeredAlarms);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, AlarmState>(() => AlarmNotifier());
