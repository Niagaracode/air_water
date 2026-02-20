import '../../presentation/model/plant_model.dart';

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
    int? status,
    String? date,
  });

  Future<void> createPlant(PlantCreateRequest request);
  Future<void> updatePlant(int id, PlantCreateRequest request);
  Future<void> deletePlant(int id);
  Future<List<PlantAutocompleteInfo>> getPlantAutocomplete({String? q});
  Future<Map<String, dynamic>> getPlantWithAddresses(int id);
}
