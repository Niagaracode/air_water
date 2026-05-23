import '../../site/presentation/model/site_model.dart';
import 'model/tank_event_model.dart';
import 'model/tank_model.dart';
import 'model/tank_rule_model.dart';

abstract class TankRepository {
  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? siteName,
    String? tankName,
    int? status,
    List<int>? companyIds,
  });
  Future<List<SiteAutocompleteInfo>> getSitesForTankAutocomplete({String? q, int? companyId});
  Future<void> createTank(TankCreateRequest request);
  Future<void> updateTank(int id, TankCreateRequest request);
  Future<void> deleteTank(int id);
  Future<Map<String, dynamic>> getTankDropdowns();
  Future<List<String>> getTankNameSuggestions({String? q});
  Future<List<TankProduct>> getProducts();
  Future<List<Tank>> getTanks({int? siteId});

  Future<Map<String, dynamic>> getTankReadings(int tankId, String day);
  Future<List<TankEventModel>> getTankEvents(int tankId, String day);
  Future<List<TankRuleModel>> getAllTankRules();
}