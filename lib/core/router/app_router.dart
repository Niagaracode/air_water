import 'package:air_water/features/group/user_group_layout.dart';
import 'package:air_water/features/message_template/message_template_layout.dart';
import 'package:air_water/features/product/product_layout.dart';
import 'package:air_water/features/reports/report_layout.dart';
import 'package:air_water/features/roaster/roaster_layout.dart';
import 'package:air_water/features/rule/rule_layout.dart';
import 'package:air_water/features/user/user_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_layout.dart';
import '../../app_startup/app_startup.dart';
import '../../features/dashboard/dashboard_layout.dart';
import '../../features/device/device_layout.dart';
import '../../features/plant/plant_layout.dart';
import '../../controller/screen_controller.dart';
import '../../features/tank/tank_layout.dart';
import 'router_refresh_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: refresh,

    redirect: (context, state) {
      final startup = ref.watch(appStartupProvider);
      final location = state.matchedLocation;

      if (startup.isLoading) {
        return location == '/loading' ? null : '/loading';
      }

      final status = startup.value;

      if (status == AppStartupState.unauthenticated) {
        return location == '/login' ? null : '/login';
      }

      if (status == AppStartupState.authenticated &&
          (location == '/login' || location == '/loading')) {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => LoginLayout(child: SizedBox()),
      ),

      // SHELL / SCREEN CONTROLLER
      ShellRoute(
        builder: (context, state, child) {
          return ScreenController(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardLayout(),
          ),
          GoRoute(
            path: '/plant',
            builder: (_, __) => const PlantLayout(),
          ),
          GoRoute(
            path: '/tank',
            builder: (_, __) => const TankLayout(),
          ),
          GoRoute(
            path: '/device',
            builder: (_, __) => const DeviceLayout(),
          ),
          GoRoute(
            path: '/product',
            builder: (_, __) => const ProductLayout(),
          ),
          GoRoute(
            path: '/user',
            builder: (_, __) => const UserLayout(),
          ),
          GoRoute(
            path: '/group',
            builder: (_, __) => const UserGroupLayout(),
          ),
          GoRoute(
            path: '/rule',
            builder: (_, __) => const RuleLayout(),
          ),
          GoRoute(
            path: '/message-template',
            builder: (_, __) => const MessageTemplateLayout(),
          ),
          GoRoute(
            path: '/roaster',
            builder: (_, __) => const RoasterLayout(),
          ),
          GoRoute(
            path: '/report',
            builder: (_, __) => const ReportLayout(),
          ),
        ],
      ),
    ],
  );
});