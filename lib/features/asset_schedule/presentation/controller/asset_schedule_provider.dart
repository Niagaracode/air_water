import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../tank/data/api/tank_api.dart';
import '../../../../core/network/api_client.dart';
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
      state = state.copyWith(page: 1, schedules: [], isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final tankApi = TankApi(ref.read(apiClientProvider));
      final response = await tankApi.getTanksGrouped(
        page: state.page,
        limit: 20,
      );

      final List<AssetScheduleModel> newSchedules = [];
      final random = Random();
      final now = DateTime.now();

      for (final tankGroup in response.data) {
        for (final tank in tankGroup.tanks) {
          // Mock data for demonstration as in reference image
          final currentLevel = 20.0 + random.nextInt(60);
          final depletionRate = 2.0 + random.nextDouble() * 5.0;
          final daysToRunout = (currentLevel / depletionRate).floor();
          
          final runoutDate = now.add(Duration(days: daysToRunout, hours: random.nextInt(24)));
          final nextRefill = daysToRunout > 2 
              ? now.add(Duration(days: max(1, daysToRunout - 2), hours: 9))
              : null;

          final forecasts = List.generate(10, (index) {
            final date = now.add(Duration(days: index));
            final val = currentLevel + (index * random.nextDouble() * 10) % 100;
            return AssetScheduleForecast(
              date: date,
              value: val,
              status: val < 20 ? 'critical' : (val < 40 ? 'warning' : 'normal'),
            );
          });

          newSchedules.add(AssetScheduleModel(
            plantId: tank.plantId ?? 0,
            plantName: tankGroup.plantName,
            tankId: tank.tankId,
            tankNumber: tank.tankNumber,
            item: 'Level',
            siteLocation: '${tankGroup.city ?? "Unknown"}, ${tankGroup.state ?? ""}',
            runoutDate: runoutDate,
            nextScheduledRefill: nextRefill,
            unit: '% Full',
            forecast: forecasts,
          ));
        }
      }

      state = state.copyWith(
        isLoading: false,
        schedules: refresh ? newSchedules : [...state.schedules, ...newSchedules],
        totalPages: response.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilters({String? daysToRunOut, String? unit}) {
    state = state.copyWith(
      daysToRunOutFilter: daysToRunOut,
      unitFilter: unit,
    );
    loadData(refresh: true);
  }
}

final assetScheduleProvider = NotifierProvider<AssetScheduleNotifier, AssetScheduleState>(
  AssetScheduleNotifier.new,
);
