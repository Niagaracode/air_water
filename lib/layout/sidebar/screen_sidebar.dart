import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_config.dart';
import '../../core/router/sidebar_routes.dart';
import '../../core/user_config/user_role.dart';
import '../provider/sidebar_provider.dart';
import '../widgets/nave_menu.dart';
import '../widgets/sidebar_menu_config.dart';
import '../widgets/sidebar_menu_item.dart';

class ScreenSidebar extends ConsumerWidget {
  const ScreenSidebar({super.key, required this.userRole, required this.isNarrow});
  final UserRole userRole;
  final bool isNarrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isExpanded = ref.watch(sidebarExpandedProvider);
    final location = GoRouterState.of(context).uri.toString();

    if (isNarrow) {
      isExpanded = true;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: isExpanded ? 250 : 72,
        child: Material(
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                right: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (isNarrow) ...[
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
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],

                SidebarGroup(
                  title: 'MAIN MENU',
                  color: const Color(0xFF60A5FA), // light blue
                  items: mainMenu,
                  location: location,
                  isExpanded: isExpanded,
                  role: userRole,
                  isNarrow: isNarrow,
                ),
                SidebarGroup(
                  title: 'ASSETS',
                  color: const Color(0xFFFB923C), // light orange
                  items: configurationMenu,
                  location: location,
                  isExpanded: isExpanded,
                  role: userRole,
                  isNarrow: isNarrow,
                ),
                SidebarGroup(
                  title: 'USER',
                  color: const Color(0xFF2DD4BF), // light teal
                  items: userMenu,
                  location: location,
                  isExpanded: isExpanded,
                  role: userRole,
                  isNarrow: isNarrow,
                ),
                SidebarGroup(
                  title: 'EVENTS CONFIG',
                  color: const Color(0xFFF87171), // light red
                  items: eventsMenu,
                  location: location,
                  isExpanded: isExpanded,
                  role: userRole,
                  isNarrow: isNarrow,
                ),
                SidebarGroup(
                  title: 'EVENTS',
                  color: const Color(0xFFC084FC), // light purple
                  items: reportMenu,
                  location: location,
                  isExpanded: isExpanded,
                  role: userRole,
                  isNarrow: isNarrow,
                ),

                _buildFooterLogo(isExpanded),
              ],
            ),
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
            color: Colors.grey.shade300,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 8),
          SvgPicture.asset(
            isExpanded
                ? AppConfig.current.companyLogoPath
                : AppConfig.current.companySmallLogoPath,
            height: 30,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

/// A single sidebar group, styled after a browser bookmarks-bar
/// folder: a soft-colored header label and children indented under
/// a thin colored left border.
class SidebarGroup extends StatelessWidget {
  const SidebarGroup({
    super.key,
    required this.title,
    required this.color,
    required this.items,
    required this.location,
    required this.isExpanded,
    required this.role,
    required this.isNarrow,
  });

  final String title;
  final Color color;
  final List<SidebarMenuItem> items;
  final String location;

  /// Whether the whole sidebar is in "wide" mode (icons + labels)
  /// vs the collapsed icon-only rail.
  final bool isExpanded;

  final UserRole role;
  final bool isNarrow;

  void _handleTap(BuildContext context, String? route) {
    if (isNarrow) Navigator.of(context).maybePop();
    if (route != null) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems =
    items.where((item) => item.allowedRoles.contains(role)).toList();

    if (filteredItems.isEmpty) return const SizedBox.shrink();

    // Icon-only rail: no group chrome, just the icons stacked.
    if (!isExpanded) {
      return Column(
        children: filteredItems.map((item) {
          final route = menuRoutes[item.key];
          return NaveMenu(
            icon: item.icon,
            iconColor: item.iconColor,
            label: item.label,
            isExpanded: false,
            isSelected: route != null && location == route,
            onTap: () => _handleTap(context, route),
          );
        }).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Soft-colored group header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.6,
              ),
            ),
          ),

          /// Children — indented, thin colored left border, matching
          /// the "folder contents" look from the reference.
          Container(
            margin: const EdgeInsets.only(top: 7),
            child: Column(
              children: filteredItems.map((item) {
                final route = menuRoutes[item.key];
                return NaveMenu(
                  icon: item.icon,
                  iconColor: item.iconColor,
                  label: item.label,
                  isExpanded: true,
                  isSelected: route != null && location == route,
                  onTap: () => _handleTap(context, route),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}