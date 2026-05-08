import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/setting_model.dart';
import '../../data/api/setting_api.dart';
import '../../domain/repository/setting_repository.dart';
import '../../data/repository/setting_repository_impl.dart';
import '../../../../core/network/http/api_service.dart';

class SettingState {
  final List<SettingGroup> groupedSettings;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final int totalEntries;
  final String searchName;
  final String? parameterType;
  final int? selectedSiteId;
  final int? selectedStatus;

  SettingState({
    this.groupedSettings = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.totalEntries = 0,
    this.searchName = '',
    this.parameterType,
    this.selectedSiteId,
    this.selectedStatus,
  });

  SettingState copyWith({
    List<SettingGroup>? groupedSettings,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    int? totalEntries,
    String? searchName,
    String? parameterType,
    int? selectedSiteId,
    int? selectedStatus,
    bool clearParameterType = false,
    bool clearSiteId = false,
    bool clearStatus = false,
  }) {
    return SettingState(
      groupedSettings: groupedSettings ?? this.groupedSettings,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
      searchName: searchName ?? this.searchName,
      parameterType: clearParameterType ? null : (parameterType ?? this.parameterType),
      selectedSiteId: clearSiteId ? null : (selectedSiteId ?? this.selectedSiteId),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }
}

class SettingNotifier extends Notifier<SettingState> {
  static const int _limit = 50;
  int _lastRequestTimestamp = 0;

  @override
  SettingState build() {
    ref.keepAlive();
    Future.microtask(() => loadSettings());
    return SettingState();
  }

  Future<void> loadSettings({bool isReload = false}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    if (state.groupedSettings.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, page: 1, groupedSettings: []);
    }

    try {
      final repository = ref.read(settingRepositoryProvider);
      final response = await repository.getSettingsGrouped(
        page: 1,
        limit: _limit,
        name: state.searchName,
        parameterType: state.parameterType,
        plantId: state.selectedSiteId,
        isActive: state.selectedStatus,
      );

      if (timestamp != _lastRequestTimestamp) return;

      final processedGroups = response.data.map(_injectMockDeviceData).toList();

      state = state.copyWith(
        groupedSettings: processedGroups,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
      );
    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(settingRepositoryProvider);
      final response = await repository.getSettingsGrouped(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
        parameterType: state.parameterType,
        plantId: state.selectedSiteId,
        isActive: state.selectedStatus,
      );

      if (timestamp != _lastRequestTimestamp) return;

      final nextGroups = response.data.map(_injectMockDeviceData).toList();
      final updatedGroups = [...state.groupedSettings, ...nextGroups];

      state = state.copyWith(
        groupedSettings: updatedGroups,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  SettingGroup _injectMockDeviceData(SettingGroup group) {
    return SettingGroup(
      siteId: group.siteId,
      siteName: group.siteName,
      siteOrganizationCode: group.siteOrganizationCode,
      siteAddressLine1: group.siteAddressLine1,
      siteCity: group.siteCity,
      siteState: group.siteState,
      sitePincode: group.sitePincode,
      settings: group.settings.map((setting) {
        double val = 45.0 + (setting.id % 30);
        String unit = '%';
        if (setting.parameterType?.toLowerCase() == 'pressure') {
          val = 110.0 + (setting.id % 40);
          unit = 'Psi';
        } else if (setting.parameterType?.toLowerCase() == 'battery') {
          val = 3.6;
          unit = 'V';
        }
        
        return Setting(
          id: setting.id,
          name: setting.name,
          description: setting.description,
          companyId: setting.companyId,
          companyName: setting.companyName,
          siteId: setting.siteId,
          siteName: setting.siteName,
          tankId: setting.tankId,
          tankNumber: setting.tankNumber,
          deviceId: setting.deviceId,
          deviceName: setting.deviceName,
          parameterType: setting.parameterType,
          conditionType: setting.conditionType,
          thresholds: setting.thresholds,
          importance: setting.importance,
          statusLabel: setting.statusLabel,
          messageTemplateId: setting.messageTemplateId,
          templateName: setting.templateName,
          isActive: setting.isActive,
          status: setting.status,
          rosterName: setting.rosterName,
          currentValue: val,
          currentValueUnit: unit,
        );
      }).toList(),
    );
  }

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
  }

  void setParameterType(String? type) {
    state = state.copyWith(parameterType: type);
    loadSettings(isReload: true);
  }

  void setSiteId(int? siteId) {
    state = state.copyWith(selectedSiteId: siteId);
    loadSettings(isReload: true);
  }

  void setSelectedStatus(int? status) {
    state = state.copyWith(selectedStatus: status);
    loadSettings(isReload: true);
  }

  void clearFilters() {
    state = state.copyWith(
      searchName: '',
      clearParameterType: true,
      clearSiteId: true,
      clearStatus: true,
    );
    loadSettings(isReload: true);
  }

  Future<bool> createSetting(Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(settingRepositoryProvider);
      await repository.createSetting(data);
      state = state.copyWith(isProcessing: false);
      await loadSettings(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSetting(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(settingRepositoryProvider);
      await repository.updateSetting(id, data);
      state = state.copyWith(isProcessing: false);
      await loadSettings(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSetting(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(settingRepositoryProvider);
      await repository.deleteSetting(id);
      state = state.copyWith(isProcessing: false);
      await loadSettings(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<SettingAutocompleteInfo>> searchSettings(String query) async {
    try {
      final repository = ref.read(settingRepositoryProvider);
      return await repository.searchSettings(q: query);
    } catch (e) {
      return [];
    }
  }
}

final settingApiProvider = Provider<SettingApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return SettingApi(client);
});

final settingRepositoryProvider = Provider<SettingRepository>((ref) {
  final api = ref.watch(settingApiProvider);
  return SettingRepositoryImpl(api);
});

final settingProvider = NotifierProvider<SettingNotifier, SettingState>(
  SettingNotifier.new,
);
