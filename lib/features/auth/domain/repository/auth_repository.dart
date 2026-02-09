
abstract class AuthRepository {
  Future<void> login(String username, String password);
  Future<void> logout();
  //Future<bool> restoreSession();
  Future<String?> getUserRole();
}