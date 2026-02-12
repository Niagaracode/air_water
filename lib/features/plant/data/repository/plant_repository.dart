import '../../model/plant_model.dart';

abstract class PlantRepository {
  Future<PlantResponse> getPlants({
    int page = 1,
    int limit = 10,
    String? search,
  });

  Future<PlantGroupedResponse> getPlantsGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? companyId,
  });

  Future<void> createPlant(PlantCreateRequest request);
}
