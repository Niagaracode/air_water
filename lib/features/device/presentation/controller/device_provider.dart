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

  DeviceState({
    required this.groupedDevices,
    required this.isLoading,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    required this.expandedGroups,
  });

  DeviceState copyWith({
    List<DeviceGroup>? groupedDevices,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    Set<String?>? expandedGroups,
  }) {
    return DeviceState(
      groupedDevices: groupedDevices ?? this.groupedDevices,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      expandedGroups: expandedGroups ?? this.expandedGroups,
    );
  }
}

class DeviceNotifier extends Notifier<DeviceState> {
  @override
  DeviceState build() {
    return DeviceState(
      groupedDevices: [],
      isLoading: false,
      expandedGroups: {},
    );
  }

  Future<void> loadGroupedDevices({
    String? deviceId,
    String? plantName,
    String? searchQuery,
    int? siteId,
    int? companyId,
  }) async {
    state = state.copyWith(isLoading: true, page: 1, groupedDevices: []);
    try {
      final repository = ref.read(deviceRepositoryProvider);
      final response = await repository.getDevicesGrouped(
        page: 1,
        deviceId: deviceId,
        plantName: plantName,
        searchQuery: searchQuery,
        siteId: siteId,
        companyId: companyId,
      );

      final expandedGroups = <String?>{};
      for (var group in response.data) {
        expandedGroups.add(group.plantOrganizationCode);
      }

      state = state.copyWith(
        groupedDevices: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? deviceId,
    String? plantName,
    String? searchQuery,
    int? siteId,
    int? companyId,
  }) async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(deviceRepositoryProvider);
      final response = await repository.getDevicesGrouped(
        page: nextPage,
        deviceId: deviceId,
        plantName: plantName,
        searchQuery: searchQuery,
        siteId: siteId,
        companyId: companyId,
      );

      final updatedGroups = [...state.groupedDevices, ...response.data];
      final expandedGroups = Set<String?>.from(state.expandedGroups);
      for (var group in response.data) {
        expandedGroups.add(group.plantOrganizationCode);
      }

      state = state.copyWith(
        groupedDevices: updatedGroups,
        isLoading: false,
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
