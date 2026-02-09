import '../repository/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;

  LoginUseCase(this._repo);

  Future<void> execute(String username, String password) {
    return _repo.login(username, password);
  }
}