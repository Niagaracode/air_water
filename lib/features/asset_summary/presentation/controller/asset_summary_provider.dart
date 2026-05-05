import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tank/presentation/model/tank_model.dart';
import '../../../tank/data/api/tank_api.dart';
import '../../../setting/data/api/setting_api.dart';
import '../../../setting/presentation/model/setting_model.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../../core/network/http/api_service.dart';
import '../model/asset_summary_model.dart';

class AssetSummaryState {
  final bool isLoading;
  final String? error;
  final List<AssetSummaryGroup> groups;
  final List<AssetGroupData> assetGroups;
  final String? plantFilter;
  final String? tankFilter;
  final String? importanceFilter;
  final int page;
  final int totalPages;

  const AssetSummaryState({
    this.isLoading = false,
    this.error,
    this.groups = const [],
    this.assetGroups = const [],
    this.plantFilter,
    this.tankFilter,
    this.importanceFilter,
    this.page = 1,
    this.totalPages = 1,
  });

  AssetSummaryState copyWith({
    bool? isLoading,
    String? error,
    List<AssetSummaryGroup>? groups,
    List<AssetGroupData>? assetGroups,
    String? plantFilter,
    String? tankFilter,
    String? importanceFilter,
    int? page,
    int? totalPages,
  }) {
    return AssetSummaryState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      groups: groups ?? this.groups,
      assetGroups: assetGroups ?? this.assetGroups,
      plantFilter: plantFilter ?? this.plantFilter,
      tankFilter: tankFilter ?? this.tankFilter,
      importanceFilter: importanceFilter ?? this.importanceFilter,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class AssetSummaryNotifier extends Notifier<AssetSummaryState> {
  @override
  AssetSummaryState build() {
    return const AssetSummaryState();
  }

  Future<void> loadData({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, groups: [], isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final tankApi = TankApi(ref.read(apiClientProvider));
      final response = await tankApi.getTanksGrouped(
        page: state.page,
        limit: 20,
        siteName: state.plantFilter,
        tankName: state.tankFilter,
      );

      final settingApi = SettingApi(ref.read(apiClientProvider));

      // Fetch all active settings to map them to tanks
      final settingsResponse = await settingApi.getSettings(
        limit: 1000,
        isActive: 1,
      );
      final allSettings = settingsResponse.data;

      final userState = ref.read(userProvider);
      final currentUser = userState.currentUser;
      final isTechnician = currentUser?.roleId == 5;

      // Collect all rosters the technician belongs to
      final userRosters = currentUser?.rosters ?? [];
      final primaryRoster = currentUser?.messageCategoryName;
      final Set<String> authorizedRosters = {
        ...userRosters.map((e) => e.toLowerCase()),
        if (primaryRoster != null) primaryRoster.toLowerCase(),
      };

      // Logic for Technicians: Derive authorized assets from Rules linked to their Rosters
      Set<int> authorizedPlantIds = {};
      Set<int> authorizedTankIds = {};

      if (isTechnician) {
        // Option 1: Direct Assignments (if any)
        authorizedPlantIds.addAll(
          currentUser?.assignedSites?.expand((ap) => ap.siteIds).toSet() ?? {},
        );

        // Option 2: Rules matching any of the technician's rosters/teams
        if (authorizedRosters.isNotEmpty) {
          final rosterRules = allSettings.where(
            (s) =>
                s.rosterName != null &&
                authorizedRosters.contains(s.rosterName!.toLowerCase()),
          );

          authorizedPlantIds.addAll(
            rosterRules.where((s) => s.siteId != null).map((s) => s.siteId!),
          );
          authorizedTankIds.addAll(
            rosterRules.where((s) => s.tankId != null).map((s) => s.tankId!),
          );
        }
      }

      final List<AssetSummaryGroup> newGroups = [];
      final Set<int> processedTankIds = {};

      // 1. Process Site Groups (Standard Hierarchy)
      for (final tankGroup in response.data) {
        // If technician, skip if the plant is not in authorized list
        if (isTechnician && !authorizedPlantIds.contains(tankGroup.siteId)) {
          continue;
        }

        for (final tank in tankGroup.tanks) {
          if (processedTankIds.contains(tank.tankId)) continue;
          
          _addTankToGroups(tank, tankGroup.siteName, newGroups, allSettings, isTechnician, authorizedRosters);
          processedTankIds.add(tank.tankId);
        }
      }

      // 2. Process Asset Groups (Dynamic Criteria)
      for (final assetGroup in response.assetGroups) {
        for (final tank in assetGroup.tanks) {
          if (processedTankIds.contains(tank.tankId)) continue;

          _addTankToGroups(tank, assetGroup.name, newGroups, allSettings, isTechnician, authorizedRosters);
          processedTankIds.add(tank.tankId);
        }
      }

      state = state.copyWith(
        isLoading: false,
        groups: refresh ? newGroups : [...state.groups, ...newGroups],
        assetGroups: response.assetGroups,
        totalPages: response.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _addTankToGroups(
    Tank tank, 
    String groupName, 
    List<AssetSummaryGroup> groups, 
    List<Setting> allSettings,
    bool isTechnician,
    Set<String> authorizedRosters
  ) {
    final deviceId = tank.deviceId ?? 'E10038${tank.tankId.toString().padLeft(2, '0')}';
    final deviceName = tank.deviceName;

    // Filter settings for this specific tank or its plant (if tank_id is null)
    var tankSettings = allSettings
        .where(
          (r) =>
              r.tankId == tank.tankId ||
              (r.tankId == null && r.siteId == tank.siteId),
        )
        .toList();

    // If technician, further filter settings by roster/message category
    if (isTechnician && authorizedRosters.isNotEmpty) {
      tankSettings = tankSettings
          .where(
            (s) =>
                s.rosterName != null &&
                authorizedRosters.contains(s.rosterName!.toLowerCase()),
          )
          .toList();
    }

    var readings = _generateReadingsWithSettings(
      tank,
      deviceId,
      tankSettings,
    );

    if (state.importanceFilter != null) {
      readings = readings
          .where(
            (r) =>
                r.importance.toLowerCase() ==
                state.importanceFilter!.toLowerCase(),
          )
          .toList();
    }

    // Always add the tank — show default readings if no settings are configured
    if (readings.isEmpty) {
      readings = _generateDefaultReadings(tank);
    }

    groups.add(
      AssetSummaryGroup(
        tankId: tank.tankId,
        plantName: groupName,
        companyName: tank.companyName,
        tankNumber: tank.tankNumber,
        deviceId: deviceId,
        deviceName: deviceName,
        readings: readings,
      ),
    );
  }

  List<AssetSummaryReading> _generateReadingsWithSettings(
    Tank tank,
    String deviceId,
    List<Setting> settings,
  ) {
    final now = DateTime.now();
    final List<AssetSummaryReading> result = [];

    // The parameters we want to display in the new visual dashboard
    final parameters = [
      {'name': 'Gas', 'unit': '', 'defaultVal': tank.productName ?? 'Oxygen', 'isStatic': true},
      {'name': 'Pressure', 'unit': 'bar', 'defaultVal': '0.00', 'isStatic': false},
      {'name': 'Level', 'unit': 'mmWc', 'defaultVal': '0.00', 'isStatic': false},
      {'name': 'KL', 'unit': 'KL', 'defaultVal': '0.000', 'isStatic': false},
      {'name': 'Cubic Meter', 'unit': 'NM3', 'defaultVal': '0.00', 'isStatic': false},
      {'name': 'Ton', 'unit': 'Ton', 'defaultVal': '0.000', 'isStatic': false},
      {'name': 'Battery Volt', 'unit': 'V', 'defaultVal': '0.00', 'isStatic': false},
      {'name': 'Solar Volt', 'unit': 'V', 'defaultVal': '0.00', 'isStatic': false},
    ];

    for (var param in parameters) {
      final name = param['name'] as String;
      final unit = param['unit'] as String;
      final isStatic = param['isStatic'] as bool;
      
      final setting = settings
          .where((r) => r.parameterType?.toLowerCase() == name.toLowerCase())
          .firstOrNull;

      String value = param['defaultVal'] as String;
      String alarmLevelsText = 'No rules';
      String importance = 'Low';
      
      if (setting != null) {
        final u = ' $unit';
        importance = setting.importance ?? 'Medium';

        if (setting.conditionType == 'BETWEEN') {
          alarmLevelsText = 'L1: ${setting.threshold1}$u, L2: ${setting.threshold2}$u';
        } else if (setting.conditionType == 'LESS THAN' || setting.conditionType == '<') {
          alarmLevelsText = 'L1: ${setting.threshold1}$u';
        } else if (setting.conditionType == 'GREATER THAN' || setting.conditionType == '>') {
          alarmLevelsText = 'H1: ${setting.threshold1}$u';
        } else {
          alarmLevelsText = '${setting.conditionType} ${setting.threshold1}$u';
        }
        
        // Mocking values if they are not real yet
        if (!isStatic) {
           if (name == 'Level') value = '${(40 + (tank.tankId % 50)).toStringAsFixed(2)} %';
           else if (name == 'Pressure') value = '103.00 $unit';
           else if (name == 'Battery Volt') value = '3.6 V';
           else if (name == 'Solar Volt') value = '12.79 V';
        }
      } else {
        // Even if no setting, provide default display for dashboard consistency
        if (name == 'Gas') value = tank.productName ?? 'O₂';
      }

      result.add(
        AssetSummaryReading(
          item: name,
          readingTime: now.subtract(const Duration(minutes: 10)),
          readingValue: value,
          product: tank.productName ?? 'Oxygen',
          importance: importance,
          alarmLevels: alarmLevelsText,
          deliverable: name == 'Level' ? 'Yes' : 'NA',
          rosterName: setting?.rosterName,
        ),
      );
    }

    return result;
  }


  /// Generates placeholder readings for tanks that have no rules/settings configured.
  /// This ensures tanks always appear in the asset summary even without alarm rules.
  List<AssetSummaryReading> _generateDefaultReadings(Tank tank) {
    final now = DateTime.now();
    return _generateReadingsWithSettings(tank, '', []);
  }


  void setFilters({String? plant, String? tank, String? importance}) {

    state = state.copyWith(
      plantFilter: plant,
      tankFilter: tank,
      importanceFilter: importance,
    );
    loadData(refresh: true);
  }

  void clearFilters() {
    state = state.copyWith(
      plantFilter: null,
      tankFilter: null,
      importanceFilter: null,
    );
    loadData(refresh: true);
  }

  void nextPage() {
    if (state.page < state.totalPages) {
      state = state.copyWith(page: state.page + 1);
      loadData();
    }
  }
}

final assetSummaryProvider =
    NotifierProvider<AssetSummaryNotifier, AssetSummaryState>(
      AssetSummaryNotifier.new,
    );
