import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_startup/app_startup.dart';
import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import '../../features/user/presentation/controller/user_provider.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription _startupSub;
  late final ProviderSubscription _userSub;
  late final ProviderSubscription _roleSub;

  RouterRefreshNotifier(Ref ref) {
    _startupSub = ref.listen<AsyncValue<AppStartupState>>(
      appStartupProvider,
      (_, __) => notifyListeners(),
    );
    _userSub = ref.listen<UserState>(
      userProvider,
      (_, __) => notifyListeners(),
    );
    _roleSub = ref.listen<AsyncValue<UserRole>>(
      userRoleProvider,
      (_, __) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _startupSub.close();
    _userSub.close();
    _roleSub.close();
    super.dispose();
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});