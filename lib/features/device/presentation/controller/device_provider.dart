import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/api/device_api.dart';
import '../../data/repository/device_repository_impl.dart';
import '../model/device_model.dart';
import '../../../plant/presentation/model/plant_model.dart';

class DeviceState {
  final List<DeviceGroup> groupedDevices;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final Set<String?> expandedGroups;
  final String searchPlant;
  final String searchDevice;
  final int? selectedSiteId;
  final int? selectedCompanyId;
  final int totalEntries;

  DeviceState({
    required this.groupedDevices,
    required this.isLoading,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    required this.expandedGroups,
    this.searchPlant = '',
    this.searchDevice = '',
    this.selectedSiteId,
    this.selectedCompanyId,
    this.totalEntries = 0,
  });

  DeviceState copyWith({
    List<DeviceGroup>? groupedDevices,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    Set<String?>? expandedGroups,
    String? searchPlant,
    String? searchDevice,
    int? selectedSiteId,
    int? selectedCompanyId,
    int? totalEntries,
  }) {
    return DeviceState(
      groupedDevices: groupedDevices ?? this.groupedDevices,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      searchPlant: searchPlant ?? this.searchPlant,
      searchDevice: searchDevice ?? this.searchDevice,
      selectedSiteId: selectedSiteId ?? this.selectedSiteId,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
      totalEntries: totalEntries ?? this.totalEntries,
    );
  }
}

class DeviceNotifier extends Notifier<DeviceState> {
  @override
  DeviceState build() {
    ref.keepAlive();
    // Initial load will be handled asynchronously
    Future.microtask(() => loadGroupedDevices());
    return DeviceState(
      groupedDevices: [],
      isLoading: false,
      expandedGroups: {},
    );
  }

  void setSearchPlant(String value) {
    state = state.copyWith(searchPlant: value);
  }

  void setSearchDevice(String value) {
    state = state.copyWith(searchDevice: value);
  }

  void setSite(int? value) {
    state = state.copyWith(selectedSiteId: value);
    loadGroupedDevices();
  }

  void setCompany(int? value) {
    state = state.copyWith(selectedCompanyId: value);
    loadGroupedDevices();
  }

  void clearFilters() {
    state = state.copyWith(
      searchPlant: '',
      searchDevice: '',
      selectedSiteId: null,
      selectedCompanyId: null,
    );
    loadGroupedDevices();
  }

  Future<void> loadGroupedDevices() async {
    state = state.copyWith(isLoading: true, page: 1, groupedDevices: []);
    try {
      final repository = ref.read(deviceRepositoryProvider);
      final response = await repository.getDevicesGrouped(
        page: 1,
        plantName: state.searchPlant.isEmpty ? null : state.searchPlant,
        deviceId: state.searchDevice.isEmpty ? null : state.searchDevice,
        siteId: state.selectedSiteId,
        companyId: state.selectedCompanyId,
      );

      final expandedGroups = <String?>{};
      for (var group in response.data) {
        expandedGroups.add(group.plantOrganizationCode);
      }

      state = state.copyWith(
        groupedDevices: response.data,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(deviceRepositoryProvider);
      final response = await repository.getDevicesGrouped(
        page: nextPage,
        plantName: state.searchPlant.isEmpty ? null : state.searchPlant,
        deviceId: state.searchDevice.isEmpty ? null : state.searchDevice,
        siteId: state.selectedSiteId,
        companyId: state.selectedCompanyId,
      );

      final updatedGroups = [...state.groupedDevices, ...response.data];
      final expandedGroups = Set<String?>.from(state.expandedGroups);
      for (var group in response.data) {
        expandedGroups.add(group.plantOrganizationCode);
      }

      state = state.copyWith(
        groupedDevices: updatedGroups,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createDevice(DeviceCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(deviceRepositoryProvider);
      await repository.createDevice(request);
      state = state.copyWith(isProcessing: false);
      await loadGroupedDevices();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateDevice(int id, DeviceCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(deviceRepositoryProvider);
      await repository.updateDevice(id, request);
      state = state.copyWith(isProcessing: false);
      await loadGroupedDevices();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDevice(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(deviceRepositoryProvider);
      await repository.deleteDevice(id);
      state = state.copyWith(isProcessing: false);
      await loadGroupedDevices();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<PlantAutocompleteInfo>> searchPlants(String query) async {
    try {
      final repository = ref.read(deviceRepositoryProvider);
      return await repository.getPlantsForDeviceAutocomplete(q: query);
    } catch (e) {
      return [];
    }
  }

  void toggleGroup(String? orgCode) {
    final expanded = Set<String?>.from(state.expandedGroups);
    if (expanded.contains(orgCode)) {
      expanded.remove(orgCode);
    } else {
      expanded.add(orgCode);
    }
    state = state.copyWith(expandedGroups: expanded);
  }

  Future<Map<String, dynamic>> getDeviceDropdowns() async {
    try {
      final repository = ref.read(deviceRepositoryProvider);
      return await repository.getDeviceDropdowns();
    } catch (e) {
      return {};
    }
  }

  Future<List<String>> getDeviceNameSuggestions(String query) async {
    try {
      final repository = ref.read(deviceRepositoryProvider);
      return await repository.getDeviceNameSuggestions(query);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchTanks(
    String query, {
    int? plantId,
  }) async {
    try {
      final repository = ref.read(deviceRepositoryProvider);
      return await repository.searchTanks(query, plantId: plantId);
    } catch (e) {
      return [];
    }
  }
}

final deviceApiProvider = Provider<DeviceApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return DeviceApi(client);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final api = ref.watch(deviceApiProvider);
  return DeviceRepositoryImpl(api);
});

final deviceProvider = NotifierProvider<DeviceNotifier, DeviceState>(
  DeviceNotifier.new,
);
