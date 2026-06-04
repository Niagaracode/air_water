import 'package:air_water/features/company/company_layout.dart';
import 'package:air_water/features/dashboard/data/models/tank_data_model.dart';
import 'package:air_water/features/group/user_group_layout.dart';
import 'package:air_water/features/message_template/message_template_layout.dart';
import 'package:air_water/features/product/product_layout.dart';
import 'package:air_water/features/roaster/roaster_layout.dart';
import 'package:air_water/features/rule_group/rule_group_layout.dart';
import 'package:air_water/features/user/user_layout.dart';
import 'package:air_water/features/asset_schedule/asset_schedule_layout.dart';
import 'package:air_water/features/profile/profile_layout.dart';
import 'package:air_water/features/alarm/alarm_layout.dart';
import 'package:air_water/features/events/event_layout.dart';
import 'package:air_water/features/asset_group/asset_group_layout.dart';
import 'package:air_water/features/notification/notification_layout.dart';
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
import '../../features/tank/tank_layout.dart';
import '../../features/tank/presentation/view/tank_details_view.dart';
import '../../layout/screen_controller.dart';
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
        final currentUser = userState.currentUser;
        final roleFromStorage = ref.read(userRoleProvider).value;

        if (location == '/login' || location == '/loading') {
          // Priority 1: Check profile role (Most accurate)
          if (currentUser != null) {
            final roleId = currentUser.roleId;
            if (roleId == 6) return '/asset-summary';
            if (roleId == 5) return '/dashboard';
            return '/dashboard';
          }

          // Priority 2: Storage fallback (Faster during load)
          if (roleFromStorage != null) {
            if (roleFromStorage == UserRole.customer) return '/asset-summary';
            return '/dashboard';
          }

          return null;
        }

        // --- 🛡️ ACCESS CONTROL ---
        
        // Combine routes to restrict for non-admin roles
        final restrictedRoutes = [
          '/company',
          '/product',
        ];

        // Combine system configuration routes (Only for Admins)
        final systemRoutes = [
          '/user',
          '/group',
          '/device',
          '/message-template',
          '/roster',
          '/setting',
          '/rule-group',
          '/asset-group',
        ];

        if (currentUser != null) {
          final roleId = currentUser.roleId;

          // Customers (Role 6)
          if (roleId == 6) {
            if (restrictedRoutes.contains(location) || 
                systemRoutes.contains(location) || 
                location == '/dashboard') {
              return '/asset-summary';
            }
          }
          
          // Technicians (Role 5)
          if (roleId == 5) {
            if (restrictedRoutes.contains(location) || 
                systemRoutes.contains(location)) {
              return '/dashboard';
            }
          }

          // Super Admin (Role 1) & Company Admin (Role 2)
          if (roleId == 1 || roleId == 2) {
            if (roleId == 2 && restrictedRoutes.contains(location)) {
              return '/dashboard';
            }
            if (location == '/asset-summary' || location == '/asset-schedule') {
              return '/dashboard';
            }
          }
        } else if (roleFromStorage != null) {
          // Fallback during load/refresh
          if (roleFromStorage == UserRole.customer) {
            if (restrictedRoutes.contains(location) || 
                systemRoutes.contains(location) || 
                location == '/dashboard') {
              return '/asset-summary';
            }
          }


          if (roleFromStorage == UserRole.superAdmin || roleFromStorage == UserRole.companyAdmin) {
            if (roleFromStorage == UserRole.companyAdmin && restrictedRoutes.contains(location)) {
              return '/dashboard';
            }
            if (location == '/asset-summary' || location == '/asset-schedule') {
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
                  final tank = state.extra as TankDataModel?;
                  return TankDetailsView(tankId: id, tank: tank!);
                },
              ),
            ],
          ),
          GoRoute(path: '/device', builder: (_, __) => const DeviceLayout()),
          GoRoute(path: '/product', builder: (_, __) => const ProductLayout()),
          GoRoute(path: '/user', builder: (_, __) => const UserLayout()),
          GoRoute(path: '/group', builder: (_, __) => const UserGroupLayout()),
          GoRoute(
            path: '/message-template',
            builder: (_, __) => const MessageTemplateLayout(),
          ),
          GoRoute(path: '/roster', builder: (_, __) => const RoasterLayout()),

          GoRoute(
            path: '/asset-schedule',
            builder: (_, __) => const AssetScheduleLayout(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileLayout()),
          GoRoute(path: '/alarm', builder: (_, __) => const AlarmLayout()),
          GoRoute(path: '/event', builder: (_, __) => const EventLayout()),
          GoRoute(path: '/rule-group', builder: (_, __) => const RuleGroupLayout()),
          GoRoute(path: '/asset-group', builder: (_, __) => const AssetGroupLayout()),
          GoRoute(path: '/notification', builder: (_, __) => const NotificationLayout()),
        ],
      ),
    ],
  );
});
