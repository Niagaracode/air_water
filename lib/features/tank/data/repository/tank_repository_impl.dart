import '../../data/api/tank_api.dart';
import '../../presentation/model/tank_model.dart';
import '../../../plant/presentation/model/plant_model.dart';

abstract class TankRepository {
  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? plantName,
    String? tankName,
    int? status,
  });
  Future<List<PlantAutocompleteInfo>> getPlantsForTankAutocomplete({String? q});
  Future<void> createTank(TankCreateRequest request);
  Future<void> updateTank(int id, TankCreateRequest request);
  Future<void> deleteTank(int id);
  Future<Map<String, dynamic>> getTankDropdowns();
  Future<List<String>> getTankNameSuggestions({String? q});
  Future<List<TankProduct>> getProducts();
  Future<List<Tank>> getTanks({int? plantId});
}

class TankRepositoryImpl implements TankRepository {
  final TankApi _api;

  TankRepositoryImpl(this._api);

  @override
  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? plantName,
    String? tankName,
    int? status,
  }) {
    return _api.getTanksGrouped(
      page: page,
      limit: limit,
      plantName: plantName,
      tankName: tankName,
      status: status,
    );
  }

  @override
  Future<List<PlantAutocompleteInfo>> getPlantsForTankAutocomplete({
    String? q,
  }) {
    return _api.getPlantsForTankAutocomplete(q: q);
  }

  @override
  Future<void> createTank(TankCreateRequest request) {
    return _api.createTank(request);
  }

  @override
  Future<void> updateTank(int id, TankCreateRequest request) {
    return _api.updateTank(id, request);
  }

  @override
  Future<void> deleteTank(int id) {
    return _api.deleteTank(id);
  }

  @override
  Future<Map<String, dynamic>> getTankDropdowns() {
    return _api.getTankDropdowns();
  }

  @override
  Future<List<String>> getTankNameSuggestions({String? q}) {
    return _api.getTankNameSuggestions(q: q);
  }

  Future<List<TankProduct>> getProducts() {
    return _api.getProducts();
  }

  @override
  Future<List<Tank>> getTanks({int? plantId}) {
    return _api.getTanks(plantId: plantId);
  }
}
