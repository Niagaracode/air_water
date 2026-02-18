import '../../presentation/model/user_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../tank/presentation/model/tank_model.dart';

abstract class UserRepository {
  Future<UserSearchResponse> searchUsers({
    int page = 1,
    int limit = 50,
    String? q,
    String? username,
    String? email,
    int? roleId,
    int? companyId,
    int? status,
    int? plantId,
    int? tankId,
  });

  Future<List<User>> getUsers({String? username, int? roleId});

  Future<void> createUser(UserCreateRequest request);

  Future<void> updateUser(int id, UserCreateRequest request);

  Future<void> deleteUser(int id);

  Future<List<Role>> getRoles();

  Future<List<CompanyAutocomplete>> searchCompanies(String q);

  Future<List<PlantAutocompleteInfo>> searchPlants(String q);

  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? plantName,
    String? tankName,
    int? status,
  });

  Future<List<String>> getUserNameSuggestions(String q);

  Future<User> getCurrentUser();
}
