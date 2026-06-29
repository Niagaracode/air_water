import '../data/models/site_group_model.dart';
import '../data/models/tank_data_model.dart';

extension TankFilterExtension on List<SiteGroupModel> {
  /// Filters tanks based on region, status, search query, and product type
  List<SiteGroupModel> applyFilters({
    required String selectedRegion,
    required String selectedStatus,
    required String searchQuery,
    required String selectedProduct,
  }) {
    return map((group) {
      final filteredTanks = group.tanks.where((tank) {
        // Product filter - FIXED: use the current tank, not the group's tanks
        if (selectedProduct != 'All Product' && tank.gasType != selectedProduct) {
          return false;
        }

        // Region filter - using city (adjust if your model uses region)
        if (selectedRegion != 'All Regions' && tank.city != selectedRegion) {
          return false;
        }

        // Status filter
        if (selectedStatus != 'All Status') {
          if (!_matchesStatusFilter(tank, selectedStatus)) {
            return false;
          }
        }

        // Search filter
        if (searchQuery.isNotEmpty) {
          if (!_matchesSearchQuery(tank, searchQuery)) {
            return false;
          }
        }

        return true;
      }).toList();

      return SiteGroupModel(
        siteName: group.siteName,
        city: group.city,
        tanks: filteredTanks,
      );
    }).where((group) => group.tanks.isNotEmpty).toList();
  }

  /// Gets the total number of tanks after applying filters
  int getTotalTanksCount({
    required String selectedRegion,
    required String selectedStatus,
    required String searchQuery,
    required String selectedProduct, // ADDED this parameter
  }) {
    final filtered = applyFilters(
      selectedRegion: selectedRegion,
      selectedStatus: selectedStatus,
      searchQuery: searchQuery,
      selectedProduct: selectedProduct,
    );
    return filtered.fold(0, (sum, group) => sum + group.tanks.length);
  }

  /// Helper method to check status filter
  bool _matchesStatusFilter(TankDataModel tank, String selectedStatus) {
    final th = tank.thresholdValues;
    final isReorder = tank.level <= th.reorder;
    final isLowLevel = tank.level <= th.level && tank.level > th.reorder;
    final isLowBattery = tank.batteryV <= th.battery || tank.solarV <= th.battery;
    final isLowPressure = tank.pressure <= th.pressure;
    final isOffline = tank.status.toUpperCase() == 'OFFLINE';
    final isOnline = !isOffline;

    switch (selectedStatus) {
      case 'Online':
        return isOnline;
      case 'Offline':
        return isOffline;
      case 'Low Level':
        return isLowLevel;
      case 'Reorder':
      case 'Critical':
        return isReorder;
      case 'Low Battery':
        return isLowBattery;
      case 'Low Pressure':
        return isLowPressure;
      default:
        return true;
    }
  }

  /// Helper method to check search query
  bool _matchesSearchQuery(TankDataModel tank, String searchQuery) {
    final searchLower = searchQuery.toLowerCase();
    return tank.tankName.toLowerCase().contains(searchLower) ||
        tank.siteName.toLowerCase().contains(searchLower) ||
        tank.deviceId.toLowerCase().contains(searchLower) ||
        tank.gasType.toLowerCase().contains(searchLower);
  }
}