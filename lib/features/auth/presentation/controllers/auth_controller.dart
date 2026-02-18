import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_startup/app_startup.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../domain/repository/auth_repository.dart';
import 'auth_providers.dart';

class AuthController extends AsyncNotifier<void> {
  late final AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _repo.login(username, password);

      ref.read(appStartupProvider.notifier)
          .setAuthenticated();

      ref.invalidate(userNameProvider);
      ref.invalidate(userRoleProvider);

    });
  }

  Future<void> logout() async {
    await _repo.logout();

    /// clear cached providers
    ref.invalidate(userRoleProvider);
    ref.invalidate(userNameProvider);

    ref.read(appStartupProvider.notifier)
        .setUnauthenticated();
  }
}