import '../../presentation/model/company_model.dart';

abstract class CompanyRepository {
  Future<CompanyGroupedResponse> getGroupedCompanies({
    int page = 1,
    int limit = 10,
    String? search,
    int? status,
    String? date,
  });

  Future<List<String>> getAutocompleteSuggestions(String query);

  Future<void> createCompany(CompanyCreateRequest request);
  Future<void> updateCompany(int id, Map<String, dynamic> data);
  Future<void> deleteCompany(int id);
}
