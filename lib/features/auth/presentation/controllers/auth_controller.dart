import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app_startup/app_startup.dart';
import '../../../../core/user_config/user_role_mapper.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../domain/repository/auth_repository.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../product/provider/product_provider.dart';
import '../../../site/presentation/controller/site_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../device/presentation/controller/device_provider.dart';
import '../../../asset_group/presentation/controller/asset_group_provider.dart';
import '../../../roaster/presentation/controller/roaster_provider.dart';
import '../../../dashboard/provider/dashboard_provider.dart';
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

      final role = await _repo.getUserRole();

      if (role != null) {
        ref.read(userRoleProvider.notifier).state = mapUserRole(role);
      }

      ref.read(appStartupProvider.notifier).setAuthenticated();

      ref.invalidate(userNameProvider);
      ref.invalidate(userProvider);
    });
  }

  Future<void> logout() async {
    await _repo.logout();

    ref.read(userRoleProvider.notifier).state = null;

    ref.invalidate(userNameProvider);
    ref.invalidate(userProvider);
    ref.invalidate(siteNotifierProvider);
    ref.invalidate(tankNotifierProvider);
    ref.invalidate(deviceNotifierProvider);
    ref.invalidate(assetGroupProvider);
    ref.invalidate(rosterGroupProvider);
    ref.invalidate(roasterNotifierProvider);
    ref.invalidate(productNotifierProvider);
    ref.invalidate(tankDataProvider);
  }
}
