import 'package:air_water/controller/widgets/sidebar_header.dart';
import 'package:air_water/controller/widgets/sidebar_menu_config.dart';
import 'package:air_water/controller/widgets/sidebar_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/sidebar_routes.dart';
import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import '../provider/sidebar_provider.dart';
import 'nave_menu.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/user_config/user_role.dart';
import '../widgets/sidebar_header.dart';

class ScreenSidebar extends ConsumerWidget {
  const ScreenSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final location = GoRouterState.of(context).uri.toString();
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (role) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: isExpanded ? 250 : 80,
          child: Material(
            color: Colors.white,
            elevation: 2,
            child: Column(
              children: [
                SidebarHeader(isExpanded: isExpanded),
                Divider(height: 0, color: Colors.grey.shade300),
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
                        role: role,
                      ),
                      _buildGroup(
                        title: 'CONFIGURATION',
                        items: configurationMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),
                      _buildGroup(
                        title: 'USER',
                        items: userMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),
                      _buildGroup(
                        title: 'EVENTS',
                        items: eventsMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return SizedBox(
          width: isExpanded ? 250 : 80,
          child: Material(
            color: Colors.white,
            elevation: 2,
            child: Column(
              children: [
                SidebarHeader(isExpanded: isExpanded),
                Divider(height: 0, color: Colors.grey.shade300),
                Expanded(
                  child: ListView(
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    children: [

                      /// MAIN MENU
                      _buildGroup(
                        title: 'MAIN MENU',
                        items: mainMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),

                      /// CONFIGURATION
                      _buildGroup(
                        title: 'CONFIGURATION',
                        items: configurationMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),

                      /// USER
                      _buildGroup(
                        title: 'USER',
                        items: userMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),

                      /// EVENTS
                      _buildGroup(
                        title: 'EVENTS',
                        items: eventsMenu,
                        location: location,
                        isExpanded: isExpanded,
                        context: context,
                        role: role,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================================
  /// GROUP BUILDER WITH ROLE FILTER
  /// ================================
  Widget _buildGroup({
    required String title,
    required List<SidebarMenuItem> items,
    required String location,
    required bool isExpanded,
    required BuildContext context,
    required UserRole role,
  }) {

    /// 🔐 Filter items based on role
    final filteredItems =
    items.where((item) => item.allowedRoles.contains(role)).toList();

    /// If no items allowed → hide entire group
    if (filteredItems.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// Group Title
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

        /// Menu Items
        ...filteredItems.map((item) {
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