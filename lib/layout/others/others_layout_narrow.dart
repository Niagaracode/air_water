import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../sidebar/screen_sidebar.dart';

class OthersLayoutNarrow extends ConsumerWidget {
  final Widget child;
  final UserRole userRole;

  const OthersLayoutNarrow({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);

    return Scaffold(
      drawer: Drawer(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        child: ScreenSidebar(
          userRole: userRole, isNarrow: true,
        ),
      ),
      appBar: AppBar(
        title: Text(userRole.name),
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
                radius: 16,
                backgroundColor: primary.withValues(alpha: 0.2),
              ),
              error: (_, __) => CircleAvatar(
                radius: 16,
                backgroundColor: primary,
                child: Text(
                  'U',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            itemBuilder: (context) => [
              if (userRole == UserRole.superAdmin ||
                  userRole == UserRole.companyAdmin ||
                  userRole == UserRole.customer)
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
      body: child,
    );
  }
}