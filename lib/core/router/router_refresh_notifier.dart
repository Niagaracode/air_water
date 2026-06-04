import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_startup/app_startup.dart';
import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import '../../features/user/presentation/controller/user_provider.dart';

class RouterRefreshNotifier extends ChangeNotifier {

  late final ProviderSubscription _startupSub;
  late final ProviderSubscription _userSub;
  late final ProviderSubscription<UserRole?> _roleSub;

  RouterRefreshNotifier(Ref ref) {

    _startupSub = ref.listen<AsyncValue<AppStartupState>>(
      appStartupProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });

    _userSub = ref.listen<UserState>(
      userProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });

    _roleSub = ref.listen<UserRole?>(
      userRoleProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
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