import '../../data/api/tank_api.dart';
import '../../presentation/model/tank_model.dart';
import '../../../site/presentation/model/site_model.dart';

abstract class TankRepository {
  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? siteName,
    String? tankName,
    int? status,
  });
  Future<List<SiteAutocompleteInfo>> getSitesForTankAutocomplete({String? q});
  Future<void> createTank(TankCreateRequest request);
  Future<void> updateTank(int id, TankCreateRequest request);
  Future<void> deleteTank(int id);
  Future<Map<String, dynamic>> getTankDropdowns();
  Future<List<String>> getTankNameSuggestions({String? q});
  Future<List<TankProduct>> getProducts();
  Future<List<Tank>> getTanks({int? siteId});
  Future<Tank> getTankById(int id);
}

class TankRepositoryImpl implements TankRepository {
  final TankApi _api;

  TankRepositoryImpl(this._api);

  @override
  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? siteName,
    String? tankName,
    int? status,
  }) {
    return _api.getTanksGrouped(
      page: page,
      limit: limit,
      siteName: siteName,
      tankName: tankName,
      status: status,
    );
  }

  @override
  Future<List<SiteAutocompleteInfo>> getSitesForTankAutocomplete({
    String? q,
  }) {
    return _api.getSitesForTankAutocomplete(q: q);
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

  @override
  Future<List<TankProduct>> getProducts() {
    return _api.getProducts();
  }

  @override
  Future<List<Tank>> getTanks({int? siteId}) {
    return _api.getTanks(siteId: siteId);
  }

  @override
  Future<Tank> getTankById(int id) {
    return _api.getTankById(id);
  }
}
