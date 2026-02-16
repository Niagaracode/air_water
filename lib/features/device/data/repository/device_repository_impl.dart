import '../api/device_api.dart';
import '../../presentation/model/device_model.dart';
import '../../../plant/presentation/model/plant_model.dart';

abstract class DeviceRepository {
  Future<DeviceGroupedResponse> getDevicesGrouped({
    int page = 1,
    int limit = 50,
    String? deviceId,
    String? plantName,
    String? searchQuery,
    int? siteId,
    int? companyId,
  });
  Future<void> createDevice(DeviceCreateRequest request);
  Future<void> updateDevice(int id, DeviceCreateRequest request);
  Future<void> deleteDevice(int id);
  Future<List<PlantAutocompleteInfo>> getPlantsForDeviceAutocomplete({
    String? q,
  });
  Future<Map<String, dynamic>> getDeviceDropdowns();
  Future<List<String>> getDeviceNameSuggestions(String q);
  Future<List<Map<String, dynamic>>> searchTanks(String q, {int? plantId});
}

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceApi _api;

  DeviceRepositoryImpl(this._api);

  @override
  Future<DeviceGroupedResponse> getDevicesGrouped({
    int page = 1,
    int limit = 50,
    String? deviceId,
    String? plantName,
    String? searchQuery,
    int? siteId,
    int? companyId,
  }) {
    return _api.getDevicesGrouped(
      page: page,
      limit: limit,
      deviceId: deviceId,
      plantName: plantName,
      searchQuery: searchQuery,
      siteId: siteId,
      companyId: companyId,
    );
  }

  @override
  Future<void> createDevice(DeviceCreateRequest request) {
    return _api.createDevice(request);
  }

  @override
  Future<void> updateDevice(int id, DeviceCreateRequest request) {
    return _api.updateDevice(id, request);
  }

  @override
  Future<void> deleteDevice(int id) {
    return _api.deleteDevice(id);
  }

  @override
  Future<List<PlantAutocompleteInfo>> getPlantsForDeviceAutocomplete({
    String? q,
  }) {
    return _api.getPlantsForDeviceAutocomplete(q: q);
  }

  @override
  Future<Map<String, dynamic>> getDeviceDropdowns() {
    return _api.getDeviceDropdowns();
  }

  @override
  Future<List<String>> getDeviceNameSuggestions(String q) {
    return _api.getDeviceNameSuggestions(q);
  }

  @override
  Future<List<Map<String, dynamic>>> searchTanks(String q, {int? plantId}) {
    return _api.searchTanks(q, plantId: plantId);
  }
}
