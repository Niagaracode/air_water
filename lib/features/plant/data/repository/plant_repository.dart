import '../../model/plant_model.dart';

abstract class PlantRepository {
  Future<PlantResponse> getPlants({
    int page = 1,
    int limit = 10,
    String? search,
  });

  Future<void> createPlant(PlantCreateRequest request);
}
