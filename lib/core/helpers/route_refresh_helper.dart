import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/company/presentation/controller/company_provider.dart';
import '../../features/dashboard/provider/dashboard_provider.dart';
import '../../features/device/presentation/controller/device_provider.dart';
import '../../features/site/presentation/controller/site_provider.dart';
import '../../features/tank/presentation/controller/tank_provider.dart';


class RouteRefreshHelper {

  static Future<void> refreshCurrentPage(
      WidgetRef ref,
      BuildContext context,
      ) async {

    final route = GoRouterState.of(context).matchedLocation;

    debugPrint('Refreshing Route => $route');

    // Nested Routes
    if (route.startsWith('/tank/details')) {
      //ref.invalidate(tankDetailsProvider);
      return;
    }

    switch (route) {

      case '/dashboard':
        await ref.read(tankDataProvider.notifier).refresh();
        break;

      case '/company':
        await ref
            .read(companyNotifierProvider.notifier)
            .loadGroupedCompanies(isReload: true);
        break;

      case '/site':
        await ref
            .read(siteNotifierProvider.notifier)
            .loadGroupedSites(isReload: true);
        break;

      case '/tank':
        await ref
            .read(tankNotifierProvider.notifier)
            .loadGroupedTanks();
        break;

      case '/device':
        await ref
            .read(deviceNotifierProvider.notifier)
            .loadGroupedDevices();
        break;

      default:
        debugPrint('No refresh configured for $route');
    }
  }
}