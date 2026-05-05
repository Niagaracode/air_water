import '../../presentation/model/site_model.dart';
import '../../../../core/network/http/api_service.dart';

class SiteApi {
  final ApiService _client;

  SiteApi(this._client);

  Future<SiteResponse> getSites({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    String? date,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }

    final response = await _client.get('/plants', query: query);
    return SiteResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<SiteGroupedResponse> getSitesGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? companyId,
    int? status,
    String? date,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (companyId != null && companyId.isNotEmpty) {
      query['company_id'] = companyId;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }

    final response = await _client.get('/plants/grouped', query: query);
    return SiteGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<void> createSite(SiteCreateRequest request) async {
    await _client.post('/plants', data: request.toJson());
  }

  Future<void> updateSite(int id, SiteCreateRequest request) async {
    await _client.put('/plants/$id', data: request.toJson());
  }

  Future<void> deleteSite(int id) async {
    await _client.delete('/plants/$id');
  }

  Future<List<SiteAutocompleteInfo>> getSiteAutocomplete({String? q}) async {
    final query = q != null ? {'q': q} : <String, dynamic>{};
    final response = await _client.get('/plants/autocomplete', query: query);
    final List data = response.data['data'] ?? [];
    return data
        .map(
          (e) => SiteAutocompleteInfo.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSiteWithAddresses(int id) async {
    final response = await _client.get('/plants/$id/addresses');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }
}

