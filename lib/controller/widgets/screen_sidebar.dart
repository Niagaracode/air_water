import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/sidebar_routes.dart';
import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import '../provider/sidebar_provider.dart';
import '../widgets/sidebar_header.dart';
import 'sidebar_menu_config.dart';
import 'sidebar_menu_item.dart';
import 'nave_menu.dart';

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
          width: isExpanded ? 250 : 72,
          child: Material(
            color: primary.withValues(alpha: 0.075),
            elevation: 0,
            child: Column(
              children: [
                SidebarHeader(isExpanded: isExpanded),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
    final filteredItems = items
        .where((item) => item.allowedRoles.contains(role))
        .toList();

    /// If no items allowed → hide entire group
    if (filteredItems.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Group Title — only when expanded
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              top: 16,
              bottom: 4,
              right: 16,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.40),
                letterSpacing: 1.4,
              ),
            ),
          )
        else
          const SizedBox(height: 8),

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
        const SizedBox(height: 4),
      ],
    );
  }
}
