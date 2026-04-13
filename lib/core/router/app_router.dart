import 'package:air_water/features/company/company_layout.dart';
import 'package:air_water/features/group/user_group_layout.dart';
import 'package:air_water/features/message_template/message_template_layout.dart';
import 'package:air_water/features/product/product_layout.dart';
import 'package:air_water/features/reports/report_layout.dart';
import 'package:air_water/features/roaster/roaster_layout.dart';
import 'package:air_water/features/user/user_layout.dart';
import 'package:air_water/features/asset_summary/asset_summary_layout.dart';
import 'package:air_water/features/asset_schedule/asset_schedule_layout.dart';
import 'package:air_water/features/profile/profile_layout.dart';
import 'package:air_water/features/alarm/alarm_layout.dart';
import 'package:air_water/features/events/event_layout.dart';
import 'package:air_water/features/setting/setting_layout.dart';
import 'package:air_water/features/user/presentation/controller/user_provider.dart';
import 'package:air_water/core/user_config/user_role.dart';
import 'package:air_water/core/user_config/user_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_layout.dart';
import '../../app_startup/app_startup.dart';
import '../../features/dashboard/dashboard_layout.dart';
import '../../features/device/device_layout.dart';
import '../../features/site/site_layout.dart';
import '../../controller/screen_controller.dart';
import '../../features/tank/tank_layout.dart';
import '../../features/tank/presentation/view/tank_details_view.dart';
import '../../features/tank/presentation/model/tank_model.dart';
import 'router_refresh_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.read(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: refresh,

    redirect: (context, state) {
      final startup = ref.read(appStartupProvider);
      final userState = ref.read(userProvider);
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

        final currentUser = userState.currentUser;
        final roleFromStorage = ref.read(userRoleProvider).value;

        // Combine routes to restrict for non-admin roles
        final restrictedRoutes = [
          '/company',
          '/user',
          '/group',
          '/product',
          '/device',
          '/message-template',
          '/roaster',
          '/setting',
          '/rule',
        ];

        // 1. Immediate redirection based on Storage-based Role (Eliminates "one second flash")
        if (roleFromStorage != null) {
          if (roleFromStorage == UserRole.customer) {
            // Customers should be able to access /setting and /profile as per sidebar config
            final customerRestricted = restrictedRoutes
                .where((r) => r != '/setting')
                .toList();
            if (customerRestricted.contains(location)) {
              return '/dashboard';
            }
          }
          if (roleFromStorage == UserRole.technician) {
            if (restrictedRoutes.contains(location)) {
              return '/dashboard';
            }
          }
        }

        // 2. Fallback redirection based on Profile-based RoleId (Ensures sync with Backend)
        if (currentUser != null) {
          final roleId = currentUser.roleId;

          if (roleId == 6) {
            // Customer
            // Customers should be able to access /setting and /profile as per sidebar config
            final customerRestricted = restrictedRoutes
                .where((r) => r != '/setting')
                .toList();
            if (customerRestricted.contains(location)) {
              return '/dashboard';
            }
          }

          if (roleId == 5) {
            // Technician
            if (restrictedRoutes.contains(location)) {
              return '/dashboard';
            }
          }
        }
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
          GoRoute(path: '/company', builder: (_, __) => const CompanyLayout()),
          GoRoute(path: '/site', builder: (_, __) => const SiteLayout()),
          GoRoute(
            path: '/tank',
            builder: (_, __) => const TankLayout(),
            routes: [
              GoRoute(
                path: 'details/:id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  final tank = state.extra as Tank?;
                  return TankDetailsView(tankId: id, tank: tank);
                },
              ),
            ],
          ),
          GoRoute(path: '/device', builder: (_, __) => const DeviceLayout()),
          GoRoute(path: '/product', builder: (_, __) => const ProductLayout()),
          GoRoute(path: '/user', builder: (_, __) => const UserLayout()),
          GoRoute(path: '/group', builder: (_, __) => const UserGroupLayout()),
          GoRoute(path: '/rule', builder: (_, __) => const SettingLayout()),
          GoRoute(
            path: '/message-template',
            builder: (_, __) => const MessageTemplateLayout(),
          ),
          GoRoute(path: '/roaster', builder: (_, __) => const RoasterLayout()),
          GoRoute(path: '/report', builder: (_, __) => const ReportLayout()),
          GoRoute(
            path: '/asset-summary',
            builder: (_, __) => const AssetSummaryLayout(),
          ),
          GoRoute(
            path: '/asset-schedule',
            builder: (_, __) => const AssetScheduleLayout(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileLayout()),
          GoRoute(path: '/alarm', builder: (_, __) => const AlarmLayout()),
          GoRoute(path: '/event', builder: (_, __) => const EventLayout()),
          GoRoute(path: '/setting', builder: (_, __) => const SettingLayout()),
        ],
      ),
    ],
  );
});
