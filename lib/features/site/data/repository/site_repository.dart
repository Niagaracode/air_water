import '../../presentation/model/site_model.dart';

abstract class SiteRepository {
  Future<SiteResponse> getSites({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    String? date,
  });

  Future<SiteGroupedResponse> getSitesGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? companyId,
    int? status,
    String? date,
  });

  Future<void> createSite(SiteCreateRequest request);
  Future<void> updateSite(int id, SiteCreateRequest request);
  Future<void> deleteSite(int id);
  Future<List<SiteAutocompleteInfo>> getSiteAutocomplete({String? q});
  Future<List<Map<String, dynamic>>> getSiteWithAddresses(int id);
}

