import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';
import '../core/user_config/user_role_mapper.dart';
import '../core/user_config/user_role_provider.dart';

enum AppStartupState {
  authenticated,
  unauthenticated,
}

final appStartupProvider =
AsyncNotifierProvider<AppStartupNotifier, AppStartupState>(
  AppStartupNotifier.new,
);

class AppStartupNotifier extends AsyncNotifier<AppStartupState> {

  @override
  Future<AppStartupState> build() async {
    final storage = ref.read(secureStorageProvider);

    final token = await storage.readToken();
    final role = await storage.readRole();

    if (token != null &&
        token.isNotEmpty &&
        role != null &&
        role.isNotEmpty) {

      // STORE ROLE IN MEMORY
      ref.read(userRoleProvider.notifier).state =
          mapUserRole(role);

      return AppStartupState.authenticated;
    }

    return AppStartupState.unauthenticated;
  }


  Future<void> setAuthenticated() async {
    state = const AsyncData(AppStartupState.authenticated);
  }

  Future<void> setUnauthenticated() async {
    await ref.read(secureStorageProvider).clear();
    ref.read(userRoleProvider.notifier).state = null;
    state = const AsyncData(AppStartupState.unauthenticated);
  }
}