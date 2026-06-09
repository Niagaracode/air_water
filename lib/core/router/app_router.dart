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



class AppRouter {

  static GoRouter createRouter(
      WidgetRef ref,
      ) {

    return GoRouter(

      initialLocation: '/loading',
      refreshListenable: ref.read(routerRefreshProvider),

      redirect: (context, state) {

        final startup = ref.read(appStartupProvider);
        final location = state.matchedLocation;

        /// LOADING
        if (startup.isLoading) {
          return location == '/loading' ? null : '/loading';
        }

        final status = startup.value;

        /// NOT AUTHENTICATED
        if (status == AppStartupState.unauthenticated) {
          return location == '/login' ? null : '/login';
        }

        /// AUTHENTICATED
        if (status == AppStartupState.authenticated) {
          if (location == '/login' || location == '/loading') {
            return '/dashboard';
          }
          return null;
        }
        return null;
      },

      routes: [

        /// LOADING
        GoRoute(
          path: '/loading',
          builder: (_, __) {
            return const Scaffold(body: Center(child:
                CircularProgressIndicator(),
              ),
            );
          },
        ),

        /// LOGIN
        GoRoute(
          path: '/login',
          builder: (_, __) {
            return const LoginLayout(child: SizedBox());
          },
        ),

        /// MAIN APP
        ShellRoute(
          builder: (context, state, child) {
            return ScreenController(child: child);
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardLayout(),
            ),
            GoRoute(path: '/company', builder: (_, __) => const CompanyLayout()),
            GoRoute(path: '/site', builder: (_, __) => const SiteLayout()),
            GoRoute(
              path: '/tank',
              builder: (_, _) => const TankLayout(),
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
  }
}