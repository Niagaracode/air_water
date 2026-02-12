import '../../presentation/model/company_model.dart';
import '../api/company_api.dart';
import '../../domain/repository/company_repository.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final CompanyApi _api;

  CompanyRepositoryImpl(this._api);

  @override
  Future<CompanyGroupedResponse> getGroupedCompanies({
    int page = 1,
    int limit = 10,
    String? search,
    int? status,
    String? date,
  }) async {
    return await _api.getGroupedCompanies(
      page: page,
      limit: limit,
      search: search,
      status: status,
      date: date,
    );
  }

  @override
  Future<List<String>> getAutocompleteSuggestions(String query) async {
    return await _api.getAutocompleteSuggestions(query);
  }

  @override
  Future<void> createCompany(CompanyCreateRequest request) async {
    await _api.createCompany(request);
  }

  @override
  Future<void> updateCompany(int id, Map<String, dynamic> data) async {
    await _api.updateCompany(id, data);
  }

  @override
  Future<void> deleteCompany(int id) async {
    await _api.deleteCompany(id);
  }
}
