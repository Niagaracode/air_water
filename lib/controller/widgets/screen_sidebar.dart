import 'package:air_water/controller/widgets/sidebar_header.dart';
import 'package:air_water/controller/widgets/sidebar_menu_config.dart';
import 'package:air_water/controller/widgets/sidebar_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/sidebar_routes.dart';
import '../provider/sidebar_provider.dart';
import 'nave_menu.dart';

class ScreenSidebar extends ConsumerWidget {
  const ScreenSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarExpandedProvider);

    // 👇 router state is now source of truth
    final location = GoRouterState.of(context).uri.toString();

    return SizedBox(
      width: isExpanded ? 250 : 80,
      child: Material(
        color: Colors.white,
        elevation: 2,
        child: Column(
          children: [
            SidebarHeader(isExpanded: isExpanded),

            const Divider(height: 0),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildGroup(
                    title: 'MAIN MENU',
                    items: mainMenu,
                    location: location,
                    isExpanded: isExpanded,
                    context: context,
                  ),

                  _buildGroup(
                    title: 'CONFIGURATION',
                    items: configurationMenu,
                    location: location,
                    isExpanded: isExpanded,
                    context: context,
                  ),

                  _buildGroup(
                    title: 'USER',
                    items: userMenu,
                    location: location,
                    isExpanded: isExpanded,
                    context: context,
                  ),

                  _buildGroup(
                    title: 'EVENTS',
                    items: eventsMenu,
                    location: location,
                    isExpanded: isExpanded,
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup({
    required String title,
    required List<SidebarMenuItem> items,
    required String location,
    required bool isExpanded,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExpanded)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(title),
          ),

        ...items.map((item) {
          final route = menuRoutes[item.key];

          return NaveMenu(
            icon: item.icon,
            label: item.label,
            isExpanded: isExpanded,
            isSelected: route != null && location == route,
            onTap: () {
              if (route != null) {
                context.go(route);
              }
            },
          );
        }),
      ],
    );
  }
}

/*
class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final selected = ref.watch(sidebarSelectedProvider);

    return SizedBox(
      width: isExpanded ? 250 : 80,
      child: Material(
        color: Colors.white,
        elevation: 2,
        child: Column(
          children: [
            SidebarHeader(isExpanded: isExpanded),

            const Divider(height: 0),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildGroup(
                    title: 'MAIN MENU',
                    items: mainMenu,
                    selected: selected,
                    ref: ref,
                    isExpanded: isExpanded,
                  ),

                  _buildGroup(
                    title: 'CONFIGURATION',
                    items: configurationMenu,
                    selected: selected,
                    ref: ref,
                    isExpanded: isExpanded,
                  ),

                  _buildGroup(
                    title: 'USER',
                    items: userMenu,
                    selected: selected,
                    ref: ref,
                    isExpanded: isExpanded,
                  ),

                  _buildGroup(
                    title: 'EVENTS',
                    items: eventsMenu,
                    selected: selected,
                    ref: ref,
                    isExpanded: isExpanded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup({
    required String title,
    required List<SidebarMenuItem> items,
    required String selected,
    required WidgetRef ref,
    required bool isExpanded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExpanded)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: Theme.of(ref.context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(letterSpacing: 1.2),
            ),
          ),

        ...items.map(
              (item) => NaveMenu(
            icon: item.icon,
            label: item.label,
            isExpanded: isExpanded,
            isSelected: selected == item.key,
            onTap: () {
              ref
                  .read(sidebarSelectedProvider.notifier)
                  .select(item.key);
            },
          ),
        ),
      ],
    );
  }
}*/
