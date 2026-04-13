import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../tank/data/api/tank_api.dart';
import '../../../setting/data/api/setting_api.dart';
import '../../../../core/network/api_client.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../model/asset_schedule_model.dart';

class AssetScheduleState {
  final bool isLoading;
  final String? error;
  final List<AssetScheduleModel> schedules;
  final int page;
  final int totalPages;
  final String? daysToRunOutFilter;
  final String? unitFilter;

  const AssetScheduleState({
    this.isLoading = false,
    this.error,
    this.schedules = const [],
    this.page = 1,
    this.totalPages = 1,
    this.daysToRunOutFilter,
    this.unitFilter,
  });

  AssetScheduleState copyWith({
    bool? isLoading,
    String? error,
    List<AssetScheduleModel>? schedules,
    int? page,
    int? totalPages,
    String? daysToRunOutFilter,
    String? unitFilter,
  }) {
    return AssetScheduleState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      schedules: schedules ?? this.schedules,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      daysToRunOutFilter: daysToRunOutFilter ?? this.daysToRunOutFilter,
      unitFilter: unitFilter ?? this.unitFilter,
    );
  }
}

class AssetScheduleNotifier extends Notifier<AssetScheduleState> {
  @override
  AssetScheduleState build() {
    return const AssetScheduleState();
  }

  Future<void> loadData({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        page: 1,
        schedules: [],
        isLoading: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final tankApi = TankApi(apiClient);
      final settingApi = SettingApi(apiClient);

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
      final now = DateTime.now();

      final parameters = [
        {'name': 'Level', 'unit': '% Full'},
        {'name': 'Pressure', 'unit': 'Psi'},
        {'name': 'Battery', 'unit': 'V'},
      ];

      for (final tankGroup in response.data) {
        for (final tank in tankGroup.tanks) {
          // Filter settings for this specific tank or its site
          final tankSettings = allSettings
              .where(
                (r) =>
                    r.tankId == tank.tankId ||
                    (r.tankId == null && r.siteId == tank.siteId),
              )
              .toList();

          for (var param in parameters) {
            final paramName = param['name'] as String;
            final paramUnit = param['unit'] as String;

            // Check if there's a setting for this parameter
            final setting = tankSettings
                .where(
                  (r) =>
                      r.parameterType?.toLowerCase() == paramName.toLowerCase(),
                )
                .firstOrNull;

            // Authorization logic
            bool isAuthorized = false;
            if (isTechnician) {
              // Technician: Must have a setting AND that setting must belong to one of the user's rosters
              isAuthorized =
                  setting != null &&
                  userRosters.any(
                    (ur) =>
                        setting.rosterName?.toLowerCase() == ur.toLowerCase(),
                  );
            } else {
              // Admin/Customer: Level by default, or if has a setting
              isAuthorized = paramName == 'Level' || setting != null;
            }

            if (isAuthorized) {
              final currentLevel = 20.0 + random.nextInt(60);
              final depletionRate = 2.0 + random.nextDouble() * 5.0;
              final daysToRunout = (currentLevel / depletionRate).floor();

              final runoutDate = now.add(
                Duration(days: daysToRunout, hours: random.nextInt(24)),
              );
              final nextRefill = daysToRunout > 2
                  ? now.add(Duration(days: max(1, daysToRunout - 2), hours: 9))
                  : null;

              final forecasts = List.generate(10, (index) {
                final date = now.add(Duration(days: index));
                final val =
                    currentLevel + (index * random.nextDouble() * 10) % 100;
                return AssetScheduleForecast(
                  date: date,
                  value: val,
                  status: val < 20
                      ? 'critical'
                      : (val < 40 ? 'warning' : 'normal'),
                );
              });

              newSchedules.add(
                AssetScheduleModel(
                  plantId: tank.siteId ?? 0,
                  plantName: tankGroup.siteName,
                  tankId: tank.tankId,
                  tankNumber: tank.tankNumber,
                  item: paramName,
                  siteLocation:
                      '${tankGroup.city ?? "Unknown"}, ${tankGroup.state ?? ""}',
                  runoutDate: runoutDate,
                  nextScheduledRefill: nextRefill,
                  unit: paramUnit,
                  forecast: forecasts,
                ),
              );
            }
          }
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
