import '../../presentation/model/user_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../domain/repository/user_repository.dart';
import '../api/user_api.dart';

class UserRepositoryImpl implements UserRepository {
  final UserApi _api;

  UserRepositoryImpl(this._api);

  @override
  Future<UserSearchResponse> searchUsers({
    int page = 1,
    int limit = 50,
    String? q,
    String? username,
    String? email,
    int? roleId,
    int? companyId,
    int? status,
  }) async {
    return await _api.searchUsers(
      page: page,
      limit: limit,
      q: q,
      username: username,
      email: email,
      roleId: roleId,
      companyId: companyId,
      status: status,
    );
  }

  @override
  Future<List<User>> getUsers({String? username, int? roleId}) async {
    return await _api.getUsers(username: username, roleId: roleId);
  }

  @override
  Future<void> createUser(UserCreateRequest request) async {
    await _api.createUser(request);
  }

  @override
  Future<void> updateUser(int id, UserCreateRequest request) async {
    await _api.updateUser(id, request);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _api.deleteUser(id);
  }

  @override
  Future<List<Role>> getRoles() async {
    return await _api.getRoles();
  }

  @override
  Future<List<CompanyAutocomplete>> searchCompanies(String q) async {
    return await _api.searchCompanies(q);
  }

  @override
  Future<List<PlantAutocompleteInfo>> searchPlants(String q) async {
    return await _api.searchPlants(q);
  }

  @override
  Future<List<String>> getUserNameSuggestions(String q) async {
    return await _api.getUserNameSuggestions(q);
  }

  @override
  Future<User> getCurrentUser() async {
    return await _api.getCurrentUser();
  }
}
