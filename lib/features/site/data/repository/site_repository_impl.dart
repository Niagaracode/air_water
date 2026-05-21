import '../../presentation/model/site_model.dart';
import '../api/site_api.dart';
import 'site_repository.dart';

class SiteRepositoryImpl implements SiteRepository {
  final SiteApi _api;

  SiteRepositoryImpl(this._api);

  @override
  Future<SiteResponse> getSites({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    String? date,
  }) async {
    return await _api.getSites(
      page: page,
      limit: limit,
      name: name,
      status: status,
      date: date,
    );
  }

  @override
  Future<SiteGroupedResponse> getSitesGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? companyId,
    int? status,
    String? date,
  }) async {
    return await _api.getSitesGrouped(
      page: page,
      limit: limit,
      name: name,
      companyId: companyId,
      status: status,
      date: date,
    );
  }

  @override
  Future<void> createSite(SiteCreateRequest request) async {
    await _api.createSite(request);
  }

  @override
  Future<void> updateSite(int id, SiteCreateRequest request) async {
    await _api.updateSite(id, request);
  }

  @override
  Future<void> deleteSite(int id) async {
    await _api.deleteSite(id);
  }

  @override
  Future<List<SiteAutocompleteInfo>> getSiteAutocomplete({String? q}) async {
    return await _api.getSiteAutocomplete(q: q);
  }

  @override
  Future<List<Map<String, dynamic>>> getSiteWithAddresses(int id) async {
    return await _api.getSiteWithAddresses(id);
  }
}

