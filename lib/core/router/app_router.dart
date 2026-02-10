import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_layout.dart';
import '../../features/dashboard/presentation/dashboard_layout.dart';
import '../../app_startup/app_startup.dart';
import 'router_refresh_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/loading',

    refreshListenable: refresh,

    redirect: (context, state) {
      final startup = ref.watch(appStartupProvider);

      debugPrint(
          "ROUTER → loading=${startup.isLoading}, value=${startup.value}"
      );

      final location = state.matchedLocation;

      if (startup.isLoading) {
        return location == '/loading' ? null : '/loading';
      }

      final status = startup.value;

      if (status == AppStartupState.unauthenticated) {
        return location == '/login' ? null : '/login';
      }

      if (status == AppStartupState.authenticated) {
        if (location == '/login' || location == '/loading') {
          return '/dashboard';
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginLayout(),
      ),

      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardLayout(),
      ),
    ],
  );
});