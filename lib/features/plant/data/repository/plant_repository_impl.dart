import '../../presentation/model/plant_model.dart';
import '../api/plant_api.dart';
import '../../domain/repository/plant_repository.dart';

class PlantRepositoryImpl implements PlantRepository {
  final PlantApi _api;

  PlantRepositoryImpl(this._api);

  @override
  Future<PlantResponse> getPlants({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return await _api.getPlants(page: page, limit: limit, search: search);
  }

  @override
  Future<PlantGroupedResponse> getPlantsGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? companyId,
    int? status,
    String? date,
  }) async {
    return await _api.getPlantsGrouped(
      page: page,
      limit: limit,
      name: name,
      companyId: companyId,
      status: status,
      date: date,
    );
  }

  @override
  Future<void> createPlant(PlantCreateRequest request) async {
    await _api.createPlant(request);
  }

  @override
  Future<void> updatePlant(int id, PlantCreateRequest request) async {
    await _api.updatePlant(id, request);
  }

  @override
  Future<void> deletePlant(int id) async {
    await _api.deletePlant(id);
  }

  Future<List<PlantAutocompleteInfo>> getPlantAutocomplete({String? q}) async {
    return await _api.getPlantAutocomplete(q: q);
  }

  @override
  Future<Map<String, dynamic>> getPlantWithAddresses(int id) async {
    return await _api.getPlantWithAddresses(id);
  }
}
