import 'package:air_water/features/tank/data/model/tank_channel_model.dart';
import 'package:air_water/features/tank/data/tank_repository.dart';

import 'model/tank_event_model.dart';
import 'model/tank_model.dart';
import 'model/tank_rule_model.dart';
import 'tank_api.dart';
import '../../site/presentation/model/site_model.dart';

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
    List<int>? companyIds,
  }) {
    return _api.getTanksGrouped(
      page: page,
      limit: limit,
      siteName: siteName,
      tankName: tankName,
      status: status,
      companyIds: companyIds,
    );
  }

  @override
  Future<List<SiteAutocompleteInfo>> getSitesForTankAutocomplete({
    String? q,
    int? companyId,
  }) {
    return _api.getSitesForTankAutocomplete(q: q, companyId: companyId);
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
  Future<Map<String, dynamic>> getTankReadings(int tankId, String day) {
    return _api.getTankReadings(tankId, day);
  }

  @override
  Future<List<TankEventModel>> getTankEvents(int tankId, String day) {
    return _api.getTankEvents(tankId, day);
  }

  @override
  Future<List<TankRuleModel>> getAllTankRules() {
    return _api.getAllTankRules();
  }

  @override
  Future<Tank> getTankById(int id) {
    return _api.getTankById(id);
  }

  @override
  Future<List<TankChannelModel>> getTankChannels(int tankId) {
    return _api.getTankChannels(tankId);
  }

  @override
  Future<void> updateTankChannelEvent(int tankId, Map<String, dynamic> data) {
    return _api.updateTankEvent(tankId, data);
  }

}