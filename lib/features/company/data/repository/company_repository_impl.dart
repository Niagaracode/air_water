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
  Future<List<CompanyAutocompleteInfo>> getCompanyAutocomplete({
    String? q,
  }) async {
    return await _api.getCompanyAutocomplete(q: q);
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

  @override
  Future<List<Company>> getUniqueCompanyNames() async {
    return await _api.getUniqueCompanyNames();
  }

  @override
  Future<List<CompanyAddress>> getCompanyAddresses(int companyId) async {
    return await _api.getCompanyAddresses(companyId);
  }
}
