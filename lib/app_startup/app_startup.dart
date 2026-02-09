import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';

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

    if (token != null && token.isNotEmpty) {
      return AppStartupState.authenticated;
    }

    return AppStartupState.unauthenticated;
  }

  Future<void> setAuthenticated() async {
    state = const AsyncData(AppStartupState.authenticated);
  }

  Future<void> setUnauthenticated() async {
    await ref.read(secureStorageProvider).clear();
    state = const AsyncData(AppStartupState.unauthenticated);
  }
}