import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../tank/data/tank_api.dart';
import '../../../setting/data/api/setting_api.dart';
import '../../../../core/network/http/api_service.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../model/asset_schedule_model.dart';
import '../../data/api/mqtt_api.dart';

class AssetScheduleState {
  final bool isLoading;
  final String? error;
  final List<AssetScheduleModel> schedules;
  final int page;
  final int totalPages;
  final String? daysToRunOutFilter;
  final String? unitFilter;
  final DateTime? startDate;

  const AssetScheduleState({
    this.isLoading = false,
    this.error,
    this.schedules = const [],
    this.page = 1,
    this.totalPages = 1,
    this.daysToRunOutFilter,
    this.unitFilter,
    this.startDate,
  });

  AssetScheduleState copyWith({
    bool? isLoading,
    String? error,
    List<AssetScheduleModel>? schedules,
    int? page,
    int? totalPages,
    String? daysToRunOutFilter,
    String? unitFilter,
    DateTime? startDate,
  }) {
    return AssetScheduleState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      schedules: schedules ?? this.schedules,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      daysToRunOutFilter: daysToRunOutFilter ?? this.daysToRunOutFilter,
      unitFilter: unitFilter ?? this.unitFilter,
      startDate: startDate ?? this.startDate,
    );
  }
}

class AssetScheduleNotifier extends Notifier<AssetScheduleState> {
  @override
  AssetScheduleState build() {
    return const AssetScheduleState();
  }

  Future<void> loadData({bool refresh = false, DateTime? startDate}) async {
    if (refresh || startDate != null) {
      state = state.copyWith(
        page: 1,
        schedules: [],
        isLoading: true,
        startDate: startDate ?? state.startDate,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final tankApi = TankApi(apiClient);
      final settingApi = SettingApi(apiClient);

      final now = state.startDate ?? DateTime.now();

      // Fetch grouped tanks
      final response = await tankApi.getTanksGrouped(
        page: state.page,
        limit: 20,
      );

      final user = ref.read(userProvider).currentUser;
      final userRosters = user?.rosters ?? [];
      final bool isTechnician = user?.roleId == 5;

      // Fetch all active settings to map them to tanks/parameters
      final settingsResponse = await settingApi.getSettings(
        limit: 1000,
        isActive: 1,
      );
      final allSettings = settingsResponse.data;

      final List<AssetScheduleModel> newSchedules = [];
      final random = Random();

      final mqttApi = MqttApi(apiClient);

      for (final tankGroup in response.data) {
        for (final tank in tankGroup.tanks) {
          final deviceId = tank.deviceId ?? '';
          
          List<Map<String, dynamic>> deviceHistory = [];
          DateTime? last100Date;
          if (deviceId.isNotEmpty) {
            try {
              final historyData = await mqttApi.getDeviceHistory(deviceId, days: 14);
              deviceHistory = (historyData['history'] as List).cast<Map<String, dynamic>>();
              if (historyData['last_100_date'] != null) {
                last100Date = DateTime.parse(historyData['last_100_date'] as String).toLocal();
              }
            } catch (e) {
              print('Error fetching history for $deviceId: $e');
            }
          }

          final currentLevel = 20.0 + random.nextInt(60);
          final depletionRate = 2.0 + random.nextDouble() * 5.0;
          final daysToRunout = (currentLevel / depletionRate).floor();

          final runoutDate = now.add(
            Duration(days: daysToRunout, hours: random.nextInt(24)),
          );
          
          // Use real last 100% date if available, otherwise mock a future one
          final nextRefill = last100Date ?? (daysToRunout > 2
              ? now.add(Duration(days: max(1, daysToRunout - 2), hours: 9))
              : null);

          final forecasts = List.generate(14, (index) {
            final date = now.add(Duration(days: index));
            final dateStr = date.toIso8601String().split('T')[0];

            // Robust date comparison: compare YYYY-MM-DD strings
            final targetDateStr = date.toIso8601String().split('T')[0];
            
            final historyRecord = deviceHistory.where((h) {
              try {
                final hDate = DateTime.parse(h['timestamp'] as String).toLocal();
                return hDate.toIso8601String().split('T')[0] == targetDateStr;
              } catch (e) {
                return false;
              }
            }).lastOrNull;

            double? levelVal;
            double? batteryVal;

            if (historyRecord != null) {
              final payload = historyRecord['payload'] as Map<String, dynamic>;
              levelVal = (payload['TNP'] ?? 0.0).toDouble();
              batteryVal = (payload['BAT'] ?? 0.0).toDouble();
            } else {
              // No real data for this day - set to null to show "--"
              levelVal = null;
              batteryVal = null;
            }
            
            return AssetScheduleForecast(
              date: date,
              value: levelVal,
              batteryValue: batteryVal,
              status: (levelVal ?? 100) < 20
                  ? 'critical'
                  : ((levelVal ?? 100) < 40 ? 'warning' : 'normal'),
            );
          });

          newSchedules.add(
            AssetScheduleModel(
              plantId: tank.siteId ?? 0,
              plantName: tankGroup.siteName,
              tankId: tank.tankId,
              tankNumber: tank.tankNumber,
              deviceId: deviceId,
              siteLocation:
                  '${tankGroup.city ?? "Unknown"}, ${tankGroup.state ?? ""}',
              runoutDate: runoutDate,
              nextScheduledRefill: nextRefill,
              unit: '% Full',
              forecast: forecasts,
            ),
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        schedules: refresh
            ? newSchedules
            : [...state.schedules, ...newSchedules],
        totalPages: response.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilters({String? daysToRunOut, String? unit}) {
    state = state.copyWith(daysToRunOutFilter: daysToRunOut, unitFilter: unit);
    loadData(refresh: true);
  }
}

final assetScheduleProvider =
    NotifierProvider<AssetScheduleNotifier, AssetScheduleState>(
      AssetScheduleNotifier.new,
    );
