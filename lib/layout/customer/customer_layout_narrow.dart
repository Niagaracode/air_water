import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../core/app_theme/app_theme.dart';
import '../../core/helpers/route_refresh_helper.dart';
import '../../core/user_config/user_role.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import '../../features/dashboard/widgets/mqtt_connection_status.dart';
import '../../features/dashboard/widgets/sync_button.dart';
import '../../features/notification/presentation/controller/notification_provider.dart';
import '../../features/notification/presentation/widgets/notification_dropdown.dart';


class CustomerLayoutNarrow extends ConsumerStatefulWidget {
  final Widget child;
  final UserRole userRole;

  const CustomerLayoutNarrow({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  ConsumerState<CustomerLayoutNarrow> createState() => _CustomerLayoutNarrowState();
}

class _CustomerLayoutNarrowState extends ConsumerState<CustomerLayoutNarrow> {
  int _selectedIndex = 0;

  final List<CustomerMenuItem> _customerMenuItems = [
    const CustomerMenuItem(
      key: 'home',
      icon: Icons.home_rounded,
      label: 'Home',
      route: '/dashboard',
    ),
    const CustomerMenuItem(
      key: 'Report',
      icon: Icons.event_note_rounded,
      label: 'Events',
      route: '/notification',
    ),
  ];


  @override
  Widget build(BuildContext context) {
    final userNameAsync = ref.watch(userNameProvider);

    // Get current route to highlight active item
    final currentLocation = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(currentLocation);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userRole.name),
        shadowColor: primary.withValues(alpha: 0.3),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: IconThemeData(
          color: primary,
        ),
        actions: [
          const Spacer(),
          const MqttConnectionStatus(),
          const SizedBox(width: 10),
          SyncButton(
            isNarrow: true,
            onSync: () async {
              await RouteRefreshHelper.refreshCurrentPage(ref, context);
            },
          ),
          const SizedBox(width: 10),
          PopupMenuButton<void>(
            offset: const Offset(0, 48),
            elevation: 8,
            color: Colors.white,
            padding: EdgeInsets.zero,
            tooltip: 'Notification',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            position: PopupMenuPosition.under,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Badge(
                  alignment: const AlignmentDirectional(0.8, -0.8),
                  smallSize: 8,
                  backgroundColor: Colors.red.shade500,
                  isLabelVisible: ref
                      .watch(notificationNotifierProvider)
                      .notifications
                      .isNotEmpty,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<void>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: NotificationDropdown(),
              ),
            ],
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            elevation: 8,
            color: Colors.white,
            tooltip: '${AppConfig.current.appName} Account',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authControllerProvider.notifier).logout();
              } else if (value == 'profile') {
                context.go('/profile');
              }
            },
            child: userNameAsync.when(
              data: (name) => CircleAvatar(
                radius: 20,
                backgroundColor: primary,
                child: Text(
                  (name ?? 'U').isNotEmpty
                      ? (name ?? 'U')[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              loading: () => CircleAvatar(
                radius: 20,
                backgroundColor: primary.withValues(alpha: 0.2),
              ),
              error: (_, __) => CircleAvatar(
                radius: 20,
                backgroundColor: primary,
                child: Text(
                  'U',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            itemBuilder: (context) => [
              if (widget.userRole == UserRole.superAdmin ||
                  widget.userRole == UserRole.companyAdmin ||
                  widget.userRole == UserRole.customer)
                PopupMenuItem(
                  value: 'profile',
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: primary,
                      ),
                    ),
                    title: Text(
                      'Profile',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
              PopupMenuItem(
                value: 'logout',
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Colors.red.shade500,
                    ),
                  ),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ..._customerMenuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _buildNavItem(
                icon: item.icon,
                label: item.label,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  context.go(item.route);
                },
              );
            }),
            SizedBox(width: 50, child: SvgPicture.asset(
              AppConfig.current.appLogoPath,
              height: 32,
              fit: BoxFit.contain,
            ),),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primary : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primary : Colors.grey.shade500,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getCurrentIndex(String currentLocation) {
    for (int i = 0; i < _customerMenuItems.length; i++) {
      if (currentLocation.startsWith(_customerMenuItems[i].route)) {
        return i;
      }
    }
    // If route doesn't match, check if it's home or events
    if (currentLocation.contains('/home')) return 0;
    if (currentLocation.contains('/events')) return 1;
    return 0; // Default to Home
  }
}

// Model class for customer menu items
class CustomerMenuItem {
  final String key;
  final IconData icon;
  final String label;
  final String route;

  const CustomerMenuItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.route,
  });
}