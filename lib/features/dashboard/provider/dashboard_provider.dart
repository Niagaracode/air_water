import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_client.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository_impl.dart';
import '../data/tank_data_model.dart';
import '../domain/dashboard_repository.dart';
import '../presentation/model/site_group_model.dart';
import 'tank_data_notifier.dart';

// Existing providers
final dashboardApiProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return DashboardApi(client);
});

final dashboardRepoProvider = Provider<DashboardRepository>((ref) {
  final api = ref.watch(dashboardApiProvider);
  return DashboardRepositoryImpl(api);
});

// Updated: Use StateNotifierProvider instead of FutureProvider
final tankDataListProvider = StateNotifierProvider<TankDataNotifier, AsyncValue<List<TankDataModel>>>((ref) {
  final repository = ref.watch(dashboardRepoProvider);
  return TankDataNotifier(repository, ref);
});

// Updated: Grouped tanks provider that works with AsyncValue
final groupedTanksProvider = Provider<List<SiteGroupModel>>((ref) {
  final tankDataAsync = ref.watch(tankDataListProvider);

  return tankDataAsync.when(
    data: (tanks) {
      final Map<String, SiteGroupModel> grouped = {};

      for (var tank in tanks) {
        if (!grouped.containsKey(tank.siteName)) {
          grouped[tank.siteName] = SiteGroupModel(
            siteName: tank.siteName,
            siteLocation: tank.siteLocation,
            tanks: [],
          );
        }
        grouped[tank.siteName]!.tanks.add(tank);
      }

      return grouped.values.toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Updated: Statistics provider
final tankStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final tankDataAsync = ref.watch(tankDataListProvider);

  return tankDataAsync.when(
    data: (tanks) {
      final total = tanks.length;
      final active = tanks.where((t) => t.status == 'Active').length;
      final warning = tanks.where((t) => t.status == 'Warning').length;
      final critical = tanks.where((t) => t.status == 'Critical').length;
      final offline = tanks.where((t) => t.status == 'Offline').length;
      final outOfOrder = tanks.where((t) => t.status == 'Out of Order').length;
      final lowLevel = tanks.where((t) => t.level <= 20).length;
      final lowBattery = tanks.where((t) => t.batteryV <= 3).length;
      final reorderLevel = tanks.where((t) => t.level <= 15).length;

      return {
        'total': total,
        'active': active,
        'warning': warning,
        'critical': critical,
        'offline': offline,
        'outOfOrder': outOfOrder,
        'lowLevel': lowLevel,
        'lowBattery': lowBattery,
        'reorder': reorderLevel,
      };
    },
    loading: () => {
      'total': 0,
      'active': 0,
      'warning': 0,
      'critical': 0,
      'offline': 0,
      'outOfOrder': 0,
      'lowLevel': 0,
      'lowBattery': 0,
      'reorder': 0,
    },
    error: (_, __) => {
      'total': 0,
      'active': 0,
      'warning': 0,
      'critical': 0,
      'offline': 0,
      'outOfOrder': 0,
      'lowLevel': 0,
      'lowBattery': 0,
      'reorder': 0,
    },
  );
});

// Rest of your providers remain the same...
final regionFilteredTanksProvider = Provider.family<List<TankDataModel>, String>((ref, region) {
  final tankDataAsync = ref.watch(tankDataListProvider);

  return tankDataAsync.when(
    data: (tanks) {
      if (region == 'All Regions') return tanks;
      return tanks.where((tank) => tank.region == region).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});