import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/dashboard_repository.dart';

class TankDataModel {
  final int id;
  final String name;
  final String siteName;
  final String siteLocation;
  final double? capacity;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? region;
  final String? deviceId;
  
  // Telemetry Metrics
  final double? level;
  final double? currentVolume;
  final double? cum;
  final double? bat;
  final double? sol;
  final double? tnp;
  final double? ptn; // New PTN key
  final String? cd;
  final String? ct;
  final String? date;
  final String? time;
  final DateTime? lastUpdate;

  TankDataModel({
    required this.id,
    required this.name,
    required this.siteName,
    required this.siteLocation,
    this.capacity,
    required this.status,
    this.latitude,
    this.longitude,
    this.region,
    this.deviceId,
    this.level,
    this.currentVolume,
    this.cum,
    this.bat,
    this.sol,
    this.tnp,
    this.ptn,
    this.cd,
    this.ct,
    this.date,
    this.time,
    this.lastUpdate,
  });

  factory TankDataModel.fromJson(Map<String, dynamic> json) {
    return TankDataModel(
      id: json['id'],
      name: json['name'] ?? '',
      siteName: json['siteName'] ?? '',
      siteLocation: json['siteLocation'] ?? '',
      capacity: double.tryParse(json['capacity']?.toString() ?? '0'),
      status: json['status'] ?? 'Unknown',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0'),
      longitude: double.tryParse(json['longitude']?.toString() ?? '0'),
      region: json['region'],
      deviceId: json['device_id'],
      level: double.tryParse(json['level']?.toString() ?? '0'),
      currentVolume: double.tryParse(json['currentVolume']?.toString() ?? '0'),
      cum: double.tryParse(json['cum']?.toString() ?? '0'),
      bat: double.tryParse(json['bat']?.toString() ?? '0'),
      sol: double.tryParse(json['sol']?.toString() ?? '0'),
      tnp: double.tryParse(json['tnp']?.toString() ?? '0'),
      ptn: double.tryParse(json['ptn']?.toString() ?? '0'),
      cd: json['cd'],
      ct: json['ct'],
      date: json['date'],
      time: json['time'],
      lastUpdate: json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate']) : null,
    );
  }
}

// Tanks Data Provider
final tankProviderDashboard = StateNotifierProvider<TankNotifier, List<TankDataModel>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return TankNotifier(repository);
});

class TankNotifier extends StateNotifier<List<TankDataModel>> {
  final DashboardRepository _repository;
  
  TankNotifier(this._repository) : super([]) {
    loadTanks();
  }

  Future<void> loadTanks() async {
    try {
      final tanks = await _repository.getTankStatus();
      state = tanks;
    } catch (e) {
      print('Error loading tanks: $e');
    }
  }

  // Get grouped tanks by site
  List<SiteGroup> getGroupedTanks() {
    final Map<String, SiteGroup> grouped = {};

    for (var tank in state) {
      if (!grouped.containsKey(tank.siteName)) {
        grouped[tank.siteName] = SiteGroup(
          siteName: tank.siteName,
          siteLocation: tank.siteLocation,
          tanks: [],
        );
      }
      grouped[tank.siteName]!.tanks.add(tank);
    }

    return grouped.values.toList();
  }

  // Get tanks by region
  List<TankDataModel> getTanksByRegion(String region) {
    if (region == 'All Regions') return state;
    return state.where((tank) => tank.region == region).toList();
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final total = state.length;
    final active = state.where((t) => t.status == 'Active').length;
    final warning = state.where((t) => t.status == 'Warning').length;
    final critical = state.where((t) => t.status == 'Critical').length;
    final offline = state.where((t) => t.status == 'Offline').length;
    final outOfOrder = state.where((t) => t.status == 'Out of Order').length;

    return {
      'total': total,
      'active': active,
      'warning': warning,
      'critical': critical,
      'offline': offline,
      'outOfOrder': outOfOrder,
    };
  }

  void updateTankStatus(int tankId, double level, String status) {
    state = state.map((tank) {
      if (tank.id == tankId) {
        return TankDataModel(
          id: tank.id,
          name: tank.name,
          siteName: tank.siteName,
          siteLocation: tank.siteLocation,
          level: level,
          capacity: tank.capacity,
          currentVolume: (level / 100) * (tank.capacity ?? 0),
          status: status,
          lastUpdate: DateTime.now(),
          region: tank.region,
          latitude: tank.latitude,
          longitude: tank.longitude,
          deviceId: tank.deviceId,
          cum: tank.cum,
          bat: tank.bat,
          sol: tank.sol,
          tnp: tank.tnp,
          ptn: tank.ptn,
          cd: tank.cd,
          ct: tank.ct,
          date: tank.date,
          time: tank.time,
        );
      }
      return tank;
    }).toList();
  }
}

// Site Group Model
class SiteGroup {
  final String siteName;
  final String siteLocation;
  final List<TankDataModel> tanks;

  SiteGroup({
    required this.siteName,
    required this.siteLocation,
    required this.tanks,
  });
}