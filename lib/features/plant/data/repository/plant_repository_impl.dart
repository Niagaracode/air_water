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
  Future<void> createPlant(PlantCreateRequest request) async {
    await _api.createPlant(request);
  }
}
