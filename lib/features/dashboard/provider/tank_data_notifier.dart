import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/tank_data_model.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_provider.dart';

class TankDataNotifier extends StateNotifier<AsyncValue<List<TankDataModel>>> {
  final DashboardRepository _repository;
  final Ref _ref;

  TankDataNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadInitialData();
  }

  // Load initial data from API
  Future<void> _loadInitialData() async {
    try {
      final tanks = await _repository.getTankData();
      state = AsyncValue.data(tanks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update a specific tank from MQTT data
  void updateFromMqtt(Map<String, dynamic> mqttData) {
    state.whenData((tanks) {
      final deviceId = mqttData['deviceId'] as String?;
      if (deviceId == null) return;

      final updatedTanks = tanks.map((tank) {
        if (tank.deviceId == deviceId) {
          // Update tank with new MQTT data
          return TankDataModel(
            id: tank.id,
            tankName: tank.tankName,
            siteName: tank.siteName,
            deviceId: tank.deviceId,
            siteLocation: tank.siteLocation,
            level: mqttData['level'] ?? tank.level,
            pressure: mqttData['pressure'] ?? tank.pressure,
            batteryV: mqttData['battery'] ?? tank.batteryV,
            solarV: mqttData['solar'] ?? tank.solarV,
            capacity: tank.capacity,
            currentVolume: tank.currentVolume,
            status: _calculateStatus(mqttData['level'] ?? tank.level),
            lastUpdate: DateTime.now(),
            region: tank.region,
            latitude: tank.latitude,
            longitude: tank.longitude,
          );
        }
        return tank;
      }).toList();

      state = AsyncValue.data(updatedTanks);
    });
  }

  // Calculate status based on level
  String _calculateStatus(double level) {
    if (level <= 20) return 'Critical';
    if (level <= 40) return 'Warning';
    return 'Active';
  }

  // Refresh all data
  Future<void> refresh() async {
    await _loadInitialData();
  }
}

final tankDataNotifierProvider = StateNotifierProvider<TankDataNotifier, AsyncValue<List<TankDataModel>>>((ref) {
  final repository = ref.watch(dashboardRepoProvider);
  return TankDataNotifier(repository, ref);
});