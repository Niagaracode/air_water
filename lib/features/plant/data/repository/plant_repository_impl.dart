import '../../model/plant_model.dart';
import '../api/plant_api.dart';
import 'plant_repository.dart';

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
  }) async {
    return await _api.getPlantsGrouped(
      page: page,
      limit: limit,
      name: name,
      companyId: companyId,
    );
  }

  @override
  Future<void> createPlant(PlantCreateRequest request) async {
    await _api.createPlant(request);
  }
}
