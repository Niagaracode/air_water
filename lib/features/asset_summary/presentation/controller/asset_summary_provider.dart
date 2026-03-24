import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tank/presentation/model/tank_model.dart';
import '../../../tank/data/api/tank_api.dart';
import '../../../setting/data/api/setting_api.dart';
import '../../../setting/presentation/model/setting_model.dart';
import '../../../../core/network/api_client.dart';
import '../model/asset_summary_model.dart';

class AssetSummaryState {
  final bool isLoading;
  final String? error;
  final List<AssetSummaryGroup> groups;
  final String? plantFilter;
  final String? tankFilter;
  final String? importanceFilter;
  final int page;
  final int totalPages;

  const AssetSummaryState({
    this.isLoading = false,
    this.error,
    this.groups = const [],
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
        plantName: state.plantFilter,
        tankName: state.tankFilter,
      );

      final settingApi = SettingApi(ref.read(apiClientProvider));

      // Fetch all active settings to map them to tanks
      final settingsResponse = await settingApi.getSettings(limit: 1000, isActive: 1);
      final allSettings = settingsResponse.data;

      final List<AssetSummaryGroup> newGroups = [];
      for (final tankGroup in response.data) {
        for (final tank in tankGroup.tanks) {
          final deviceId = 'E10038${tank.tankId.toString().padLeft(2, '0')}';
          
          // Filter settings for this specific tank or its plant (if tank_id is null)
          final tankSettings = allSettings.where((r) => 
            r.tankId == tank.tankId || (r.tankId == null && r.plantId == tank.plantId)
          ).toList();

          var readings = _generateReadingsWithSettings(tank, deviceId, tankSettings);
          
          if (state.importanceFilter != null) {
            readings = readings.where((r) => 
               r.importance.toLowerCase() == state.importanceFilter!.toLowerCase()
            ).toList();
          }

          if (readings.isNotEmpty) {
            newGroups.add(AssetSummaryGroup(
              tankId: tank.tankId,
              plantName: tankGroup.plantName,
              tankNumber: tank.tankNumber,
              deviceId: deviceId,
              readings: readings,
            ));
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        groups: refresh ? newGroups : [...state.groups, ...newGroups],
        totalPages: response.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<AssetSummaryReading> _generateReadingsWithSettings(Tank tank, String deviceId, List<Setting> settings) {
    final now = DateTime.now();
    final List<AssetSummaryReading> result = [];

    final parameters = [
      {'name': 'Level', 'unit': '%', 'defaultVal': '43.00', 'product': true},
      {'name': 'Pressure', 'unit': 'Psi', 'defaultVal': '103.00', 'product': true},
      {'name': 'Battery', 'unit': 'V', 'defaultVal': '3.6', 'product': false},
    ];

    for (var param in parameters) {
      final name = param['name'] as String;
      final setting = settings.where((r) => r.parameterType?.toLowerCase() == name.toLowerCase()).firstOrNull;
      
      if (setting != null) {
        final unit = param['unit'] as String;
        final u = ' $unit';

        String alarmLevelsText = '';
        if (setting.conditionType == 'BETWEEN') {
          alarmLevelsText = 'L1: ${setting.threshold1}$u, L2: ${setting.threshold2}$u';
        } else if (setting.conditionType == 'LESS THAN' || setting.conditionType == '<') {
          alarmLevelsText = 'L1: ${setting.threshold1}$u';
        } else if (setting.conditionType == 'GREATER THAN' || setting.conditionType == '>') {
          alarmLevelsText = 'H1: ${setting.threshold1}$u';
        } else {
          alarmLevelsText = '${setting.conditionType} ${setting.threshold1}$u';
        }

        result.add(AssetSummaryReading(
          item: name,
          readingTime: now.subtract(const Duration(minutes: 10)),
          readingValue: name == 'Battery' 
              ? '3.6 V' 
              : '${(40 + (tank.tankId % 50)).toStringAsFixed(2)} $unit',
          product: tank.productName ?? 'Oxygen',
          importance: setting.importance ?? 'Medium',
          alarmLevels: alarmLevelsText,
          deliverable: name == 'Level' ? 'Yes' : 'NA',
          rosterName: setting.rosterName,
        ));
      }
    }

    return result;
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

final assetSummaryProvider = NotifierProvider<AssetSummaryNotifier, AssetSummaryState>(
  AssetSummaryNotifier.new,
);
