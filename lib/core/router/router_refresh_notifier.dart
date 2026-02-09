import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_startup/app_startup.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription _sub;

  RouterRefreshNotifier(Ref ref) {
    _sub = ref.listen<AsyncValue<AppStartupState>>(
      appStartupProvider,
          (_, __) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});