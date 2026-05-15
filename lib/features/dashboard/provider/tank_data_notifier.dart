import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../shared/utils/app_helper.dart';
import '../data/models/tank_data_model.dart';
import '../domain/dashboard_repository.dart';

class TankDataNotifier
    extends StateNotifier<AsyncValue<List<TankDataModel>>> {

  final DashboardRepository _repo;

  TankDataNotifier(
      this._repo, {
        bool shouldInit = false,
      }) : super(const AsyncValue.loading()) {
    if (shouldInit) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final data = await _repo.getTankData();
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    await _init();
  }

  void updateFromMqtt(Map<String, dynamic> data) {
    if (!mounted) return;

    final current = state.value;
    if (current == null) return;

    final deviceId = data['deviceId'];
    if (deviceId == null) return;

    final updated = current.map((t) {
      if (t.deviceId == deviceId) {
        return t.copyWith(
          level: data['level'] ?? t.level,
          pressure: data['pressure'] ?? t.pressure,
          batteryV: data['batteryV'] ?? t.batteryV,
          solarV: data['solarV'] ?? t.solarV,
          status: 'ONLINE',
          lastUpdate: data['lastUpdate'] ?? t.lastUpdate,
        );
      }

      return t;
    }).toList();

    if (!mounted) return;

    state = AsyncValue.data(updated);
  }

}