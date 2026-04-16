// Dummy Tanks Data Model
import 'package:flutter_riverpod/legacy.dart';

class TankDataModel {
  final String id;
  final String name;
  final String siteName;
  final String siteLocation;
  final double level;
  final double capacity;
  final double currentVolume;
  final String status;
  final DateTime lastUpdate;
  final String region;
  final double latitude;
  final double longitude;

  TankDataModel({
    required this.id,
    required this.name,
    required this.siteName,
    required this.siteLocation,
    required this.level,
    required this.capacity,
    required this.currentVolume,
    required this.status,
    required this.lastUpdate,
    required this.region,
    required this.latitude,
    required this.longitude,
  });
}

// Dummy Tanks Data Provider
final tankProviderDashboard = StateNotifierProvider<TankNotifier, List<TankDataModel>>((ref) {
  return TankNotifier();
});

class TankNotifier extends StateNotifier<List<TankDataModel>> {
  TankNotifier() : super(_generateDummyTanks());

  static List<TankDataModel> _generateDummyTanks() {
    return [
      // Arizona Tanks
      TankDataModel(
        id: 'T001',
        name: 'Main Oxygen Tank',
        siteName: 'Phoenix Medical Center',
        siteLocation: '123 Healthcare Ave, Phoenix, AZ',
        level: 85.5,
        capacity: 10000,
        currentVolume: 8550,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
        region: 'Arizona',
        latitude: 33.4484,
        longitude: -112.0740,
      ),
      TankDataModel(
        id: 'T002',
        name: 'Reserve Oxygen Tank',
        siteName: 'Phoenix Medical Center',
        siteLocation: '123 Healthcare Ave, Phoenix, AZ',
        level: 45.2,
        capacity: 5000,
        currentVolume: 2260,
        status: 'Warning',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 12)),
        region: 'Arizona',
        latitude: 33.4484,
        longitude: -112.0740,
      ),
      TankDataModel(
        id: 'T003',
        name: 'Nitrogen Tank',
        siteName: 'Mesa Community Hospital',
        siteLocation: '456 Health Blvd, Mesa, AZ',
        level: 92.0,
        capacity: 8000,
        currentVolume: 7360,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 8)),
        region: 'Arizona',
        latitude: 33.4152,
        longitude: -111.8315,
      ),
      TankDataModel(
        id: 'T004',
        name: 'Emergency Reserve',
        siteName: 'Tucson Medical Center',
        siteLocation: '789 Wellness Way, Tucson, AZ',
        level: 15.3,
        capacity: 3000,
        currentVolume: 459,
        status: 'Critical',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 20)),
        region: 'Arizona',
        latitude: 32.2226,
        longitude: -110.9747,
      ),
      TankDataModel(
        id: 'T005',
        name: 'Oxygen Tank',
        siteName: 'Sierra Vista Regional',
        siteLocation: '321 Care Drive, Sierra Vista, AZ',
        level: 0,
        capacity: 2000,
        currentVolume: 0,
        status: 'Offline',
        lastUpdate: DateTime.now().subtract(const Duration(hours: 2)),
        region: 'Arizona',
        latitude: 31.5545,
        longitude: -110.3037,
      ),

      // New Mexico Tanks
      TankDataModel(
        id: 'T006',
        name: 'Primary Oxygen Tank',
        siteName: 'Alamogordo Medical Center',
        siteLocation: '111 Desert Trail, Alamogordo, NM',
        level: 78.9,
        capacity: 6000,
        currentVolume: 4734,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 3)),
        region: 'New Mexico',
        latitude: 32.8995,
        longitude: -105.9603,
      ),
      TankDataModel(
        id: 'T007',
        name: 'Helium Tank',
        siteName: 'Roswell Health System',
        siteLocation: '222 Alien Ave, Roswell, NM',
        level: 62.4,
        capacity: 4000,
        currentVolume: 2496,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 15)),
        region: 'New Mexico',
        latitude: 33.3943,
        longitude: -104.5230,
      ),
      TankDataModel(
        id: 'T008',
        name: 'Oxygen Reserve',
        siteName: 'Carlsbad Medical Center',
        siteLocation: '333 Cavern Blvd, Carlsbad, NM',
        level: 28.7,
        capacity: 3500,
        currentVolume: 1004.5,
        status: 'Warning',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 25)),
        region: 'New Mexico',
        latitude: 32.4207,
        longitude: -104.2288,
      ),
      TankDataModel(
        id: 'T009',
        name: 'Nitrogen Tank',
        siteName: 'Las Cruces General',
        siteLocation: '444 Organ Mountain Rd, Las Cruces, NM',
        level: 95.2,
        capacity: 5000,
        currentVolume: 4760,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 7)),
        region: 'New Mexico',
        latitude: 32.3199,
        longitude: -106.7637,
      ),
      TankDataModel(
        id: 'T010',
        name: 'Oxygen Tank',
        siteName: 'Clovis Medical Center',
        siteLocation: '555 Curry Rd, Clovis, NM',
        level: 8.2,
        capacity: 2500,
        currentVolume: 205,
        status: 'Critical',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 30)),
        region: 'New Mexico',
        latitude: 34.4050,
        longitude: -103.2052,
      ),

      // Texas Tanks
      TankDataModel(
        id: 'T011',
        name: 'Main Oxygen Tank',
        siteName: 'Dallas Medical City',
        siteLocation: '777 Medical District Dr, Dallas, TX',
        level: 88.3,
        capacity: 12000,
        currentVolume: 10596,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
        region: 'Texas',
        latitude: 32.7767,
        longitude: -96.7970,
      ),
      TankDataModel(
        id: 'T012',
        name: 'Backup Oxygen',
        siteName: 'Fort Worth Hospital',
        siteLocation: '888 Cowtown Blvd, Fort Worth, TX',
        level: 52.6,
        capacity: 6000,
        currentVolume: 3156,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 10)),
        region: 'Texas',
        latitude: 32.7555,
        longitude: -97.3308,
      ),
      TankDataModel(
        id: 'T013',
        name: 'Oxygen Tank',
        siteName: 'Austin Medical Center',
        siteLocation: '999 Capital Ave, Austin, TX',
        level: 72.1,
        capacity: 7000,
        currentVolume: 5047,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 6)),
        region: 'Texas',
        latitude: 30.2672,
        longitude: -97.7431,
      ),
      TankDataModel(
        id: 'T014',
        name: 'Emergency Oxygen',
        siteName: 'Houston Methodist',
        siteLocation: '1010 Texas Ave, Houston, TX',
        level: 35.8,
        capacity: 9000,
        currentVolume: 3222,
        status: 'Warning',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 18)),
        region: 'Texas',
        latitude: 29.7604,
        longitude: -95.3698,
      ),
      TankDataModel(
        id: 'T015',
        name: 'Nitrogen Tank',
        siteName: 'Abilene Regional',
        siteLocation: '1111 Pioneer Dr, Abilene, TX',
        level: 0,
        capacity: 3000,
        currentVolume: 0,
        status: 'Out of Order',
        lastUpdate: DateTime.now().subtract(const Duration(hours: 5)),
        region: 'Texas',
        latitude: 32.4487,
        longitude: -99.7331,
      ),
      TankDataModel(
        id: 'T016',
        name: 'Oxygen Tank',
        siteName: 'Midland Memorial',
        siteLocation: '1212 Oilfield Rd, Midland, TX',
        level: 65.4,
        capacity: 4500,
        currentVolume: 2943,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 14)),
        region: 'Texas',
        latitude: 32.0026,
        longitude: -102.0778,
      ),
      TankDataModel(
        id: 'T017',
        name: 'Reserve Tank',
        siteName: 'Odessa Medical Center',
        siteLocation: '1313 Permian Dr, Odessa, TX',
        level: 42.9,
        capacity: 4000,
        currentVolume: 1716,
        status: 'Warning',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 22)),
        region: 'Texas',
        latitude: 31.8457,
        longitude: -102.3676,
      ),
      TankDataModel(
        id: 'T018',
        name: 'Oxygen Tank',
        siteName: 'Lubbock Heart Hospital',
        siteLocation: '1414 South Plains Dr, Lubbock, TX',
        level: 91.7,
        capacity: 5000,
        currentVolume: 4585,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 4)),
        region: 'Texas',
        latitude: 33.5779,
        longitude: -101.8552,
      ),
      TankDataModel(
        id: 'T019',
        name: 'Oxygen Tank',
        siteName: 'Waco Medical Center',
        siteLocation: '1515 Brazos Blvd, Waco, TX',
        level: 58.3,
        capacity: 3500,
        currentVolume: 2040.5,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 11)),
        region: 'Texas',
        latitude: 31.5493,
        longitude: -97.1467,
      ),
      TankDataModel(
        id: 'T020',
        name: 'Oxygen Tank',
        siteName: 'Tyler Medical Center',
        siteLocation: '1616 Rose Garden Dr, Tyler, TX',
        level: 73.8,
        capacity: 3800,
        currentVolume: 2804.4,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 9)),
        region: 'Texas',
        latitude: 32.3513,
        longitude: -95.3011,
      ),

      // Oklahoma Tanks
      TankDataModel(
        id: 'T021',
        name: 'Oxygen Tank',
        siteName: 'Chickasaw Nation Health Center',
        siteLocation: '1717 Tribal Way, Ada, OK',
        level: 82.5,
        capacity: 5500,
        currentVolume: 4537.5,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 7)),
        region: 'Oklahoma',
        latitude: 34.7745,
        longitude: -96.6783,
      ),
      TankDataModel(
        id: 'T022',
        name: 'Nitrogen Tank',
        siteName: 'Choctaw Nation Medical',
        siteLocation: '1818 Choctaw Rd, Durant, OK',
        level: 67.2,
        capacity: 4800,
        currentVolume: 3225.6,
        status: 'Active',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 13)),
        region: 'Oklahoma',
        latitude: 33.9940,
        longitude: -96.3949,
      ),
      TankDataModel(
        id: 'T023',
        name: 'Emergency Tank',
        siteName: 'Chickasaw Nation Health Center',
        siteLocation: '1717 Tribal Way, Ada, OK',
        level: 12.8,
        capacity: 2000,
        currentVolume: 256,
        status: 'Critical',
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 28)),
        region: 'Oklahoma',
        latitude: 34.7745,
        longitude: -96.6783,
      ),
    ];
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

  void updateTankStatus(String tankId, double level, String status) {
    state = state.map((tank) {
      if (tank.id == tankId) {
        return TankDataModel(
          id: tank.id,
          name: tank.name,
          siteName: tank.siteName,
          siteLocation: tank.siteLocation,
          level: level,
          capacity: tank.capacity,
          currentVolume: (level / 100) * tank.capacity,
          status: status,
          lastUpdate: DateTime.now(),
          region: tank.region,
          latitude: tank.latitude,
          longitude: tank.longitude,
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