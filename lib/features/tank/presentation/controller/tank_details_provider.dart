import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/tank_details_model.dart';

class TankDetailsNotifier extends Notifier<TankDetailsState> {
  @override
  TankDetailsState build() {
    return const TankDetailsState();
  }

  Future<void> loadData(int tankId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Mocking data simulation
      await Future.delayed(const Duration(milliseconds: 800));

      final now = DateTime.now();

      // Mock Data Channels
      final dataChannels = [
        DataChannel(
          name: 'Level',
          currentReading: '65 %',
          lastUpdated: now.subtract(const Duration(minutes: 5)),
          readingTime: now.subtract(const Duration(minutes: 5, seconds: 30)),
          status: 'Normal',
          percentFull: 65,
          trend: 'Down',
          deviceName: 'E1003871',
          ruleName: 'Low Level Alert',
        ),
        DataChannel(
          name: 'Pressure',
          currentReading: '120 Psi',
          lastUpdated: now.subtract(const Duration(minutes: 5)),
          readingTime: now.subtract(const Duration(minutes: 5)),
          status: 'Normal',
          percentFull: 80,
          trend: 'Stable',
          deviceName: 'E1003871',
          ruleName: 'High Pressure Alert',
        ),
      ];

      // Mock Events
      final events = [
        TankEvent(
          id: '1',
          title: 'Low Level Alert',
          description: 'Tank level below 20%',
          timestamp: now.subtract(const Duration(hours: 2)),
          status: 'Active',
          type: 'Critical',
        ),
      ];

      // Mock Readings
      final readings = [
        TankReading(
          id: '1',
          parameter: 'Level',
          value: 65,
          unit: '%',
          timestamp: now,
          status: 'Normal',
        ),
      ];

      // Mock Forecasts
      final forecasts = [
        TankForecast(
          id: '1',
          timestamp: now.add(const Duration(days: 2)),
          predictedValue: 15,
          confidence: 0.92,
          predictionType: 'Empty in',
        ),
      ];

      state = state.copyWith(
        isLoading: false,
        dataChannels: dataChannels,
        events: events,
        readings: readings,
        forecasts: forecasts,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tankDetailsProvider = NotifierProvider<TankDetailsNotifier, TankDetailsState>(
  TankDetailsNotifier.new,
);
