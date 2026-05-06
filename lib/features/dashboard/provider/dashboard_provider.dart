import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/http/api_service.dart';
import '../../../shared/utils/app_helper.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository_Impl.dart';
import '../data/models/site_group_model.dart';
import '../data/models/tank_data_model.dart';
import '../domain/dashboard_repository.dart';
import 'tank_data_notifier.dart';
import '../../user/presentation/controller/user_provider.dart';

final dashboardApiProvider = Provider((ref) {
  return DashboardApi(ref.watch(apiClientProvider));
});

final dashboardRepoProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardApiProvider));
});

final tankDataProvider = StateNotifierProvider<
    TankDataNotifier, AsyncValue<List<TankDataModel>>>((ref) {
  final user = ref.watch(userProvider).currentUser;
  final notifier = TankDataNotifier(
    ref.watch(dashboardRepoProvider),
    shouldInit: user != null,
  );
  
  // Refresh dashboard data when user profile is loaded
  ref.listen(userProvider, (previous, next) {
    if (previous?.currentUser == null && next.currentUser != null) {
      notifier.refresh();
    }
  });

  return notifier;
});



final groupedTanksProvider = Provider<List<SiteGroupModel>>((ref) {
  final tankAsync = ref.watch(tankDataProvider);

  return tankAsync.when(
    data: (tanks) {
      final Map<String, SiteGroupModel> grouped = {};
      for (var tank in tanks) {
        grouped.putIfAbsent(
          tank.siteName, () => SiteGroupModel(
            siteName: tank.siteName,
            city: tank.city,
            tanks: [],
          ),
        );
        grouped[tank.siteName]!.tanks.add(tank);
      }
      return grouped.values.toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});


final tankStatisticsProvider = Provider<Map<String, int>>((ref) {
  final tankAsync = ref.watch(tankDataProvider);

  return tankAsync.when(
    data: (tanks) {
      final now = DateTime.now();

      final active = tanks.where((t) {
        final th = t.thresholdValues;
        final minutes = durationToMinutes(th.duration);

        return now.difference(t.lastUpdate).inMinutes <= minutes;
      }).length;

      final offline = tanks.where((t) {
        final th = t.thresholdValues;
        final minutes = durationToMinutes(th.duration);

        return now.difference(t.lastUpdate).inMinutes > minutes;
      }).length;

      final lowBattery = tanks.where((t) {
        return t.batteryV < t.thresholdValues.battery;
      }).length;

      final lowLevel = tanks.where((t) {
        return t.level < t.thresholdValues.level;
      }).length;

      final lowPressure = tanks.where((t) {
        return t.pressure < t.thresholdValues.pressure;
      }).length;

      final reorder = tanks.where((t) {
        return t.level < t.thresholdValues.reorder;
      }).length;

      return {
        'total': tanks.length,
        'active': active,
        'offline': offline,
        'lowBattery': lowBattery,
        'lowLevel': lowLevel,
        'lowPressure': lowPressure,
        'reorder': reorder,
      };
    },
    loading: () => {
      'total': 0,
      'active': 0,
      'offline': 0,
      'lowBattery': 0,
      'lowLevel': 0,
      'lowPressure': 0,
      'reorder': 0,
    },
    error: (_, __) => {
      'total': 0,
      'active': 0,
      'offline': 0,
      'lowBattery': 0,
      'lowLevel': 0,
      'lowPressure': 0,
      'reorder': 0,
    },
  );
});