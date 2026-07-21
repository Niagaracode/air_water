import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../core/router/sidebar_routes.dart';
import '../../core/user_config/user_role.dart';
import '../provider/sidebar_provider.dart';
import '../widgets/sidebar_menu_config.dart';
import '../widgets/sidebar_menu_item.dart';
import '../widgets/nave_menu.dart';

class ScreenSidebar extends ConsumerWidget {
  const ScreenSidebar({super.key, required this.userRole, required this.isNarrow});
  final UserRole userRole;
  final bool isNarrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isExpanded = ref.watch(sidebarExpandedProvider);
    final location = GoRouterState.of(context).uri.toString();

    if(isNarrow){
      isExpanded = true;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: isExpanded ? 250 : 72,
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              right: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if(isNarrow)...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SvgPicture.asset(
                      AppConfig.current.appLogoPath,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Divider()
              ],

              _buildGroup(
                title: 'MAIN MENU',
                items: mainMenu,
                location: location,
                isExpanded: isExpanded,
                context: context,
                role: userRole,
              ),
              _buildGroup(
                title: 'ASSETS',
                items: configurationMenu,
                location: location,
                isExpanded: isExpanded,
                context: context,
                role: userRole,
              ),
              _buildGroup(
                title: 'USER',
                items: userMenu,
                location: location,
                isExpanded: isExpanded,
                context: context,
                role: userRole,
              ),
              _buildGroup(
                title: 'EVENTS CONFIG',
                items: eventsMenu,
                location: location,
                isExpanded: isExpanded,
                context: context,
                role: userRole,
              ),
              _buildGroup(
                title: 'EVENTS',
                items: reportMenu,
                location: location,
                isExpanded: isExpanded,
                context: context,
                role: userRole,
              ),

              _buildFooterLogo(isExpanded),
            ],

          ),
        ),
      ),
    );
  }



  Widget _buildFooterLogo(bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        children: [
          Divider(
            color: Colors.grey.shade400,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 8),
          SvgPicture.asset(
            isExpanded ? AppConfig.current.companyLogoPath : AppConfig.current.companySmallLogoPath,
            height: 30,
            fit: BoxFit.contain,
          ),
        ],
      ),
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

              if (isNarrow) {
                Navigator.of(context).pop();
              }
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