import '../../presentation/model/company_model.dart';
import '../../../../core/network/api_client.dart';

class CompanyApi {
  final ApiClient _client;

  CompanyApi(this._client);

  Future<CompanyGroupedResponse> getGroupedCompanies({
    int page = 1,
    int limit = 10,
    String? search,
    int? status,
    String? date,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }

    final response = await _client.get('/companies/grouped', query: query);
    return CompanyGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<String>> getAutocompleteSuggestions(String query) async {
    final response = await _client.get(
      '/companies/autocomplete',
      query: {'q': query},
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => item['name'] as String).toList();
  }

  Future<void> createCompany(CompanyCreateRequest request) async {
    await _client.post('/companies', data: request.toJson());
  }

  Future<void> updateCompany(int id, Map<String, dynamic> data) async {
    await _client.put('/companies/$id', data: data);
  }

  Future<void> deleteCompany(int id) async {
    await _client.delete('/companies/$id');
  }

  Future<List<Company>> getUniqueCompanyNames() async {
    final response = await _client.get('/companies/unique-names');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => Company.fromJson(item)).toList();
  }

  Future<List<CompanyAddress>> getCompanyAddresses(int companyId) async {
    final response = await _client.get('/companies/$companyId/addresses');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => CompanyAddress.fromJson(item)).toList();
  }
}
