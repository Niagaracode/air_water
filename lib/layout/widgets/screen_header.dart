import 'package:air_water/layout/widgets/sidebar_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme/app_theme.dart';
import '../../core/helpers/route_refresh_helper.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';


import '../../features/dashboard/presentation/widgets/mqtt_connection_status.dart';
import '../../features/dashboard/presentation/widgets/sync_button.dart';
import '../../features/notification/presentation/controller/notification_provider.dart';
import '../../layout/provider/sidebar_provider.dart';

class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.value ?? 'User';
    final isExpanded = ref.watch(sidebarExpandedProvider);


    return SizedBox(
      height: 65,
      width: double.infinity,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.zero),
        ),
        child: Row(
          children: [
            SidebarHeader(isExpanded: isExpanded),
            const SizedBox(width: 16),
            Text(
              'Welcome back, $userName!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            const MqttConnectionStatus(),
            const SizedBox(width: 16),
            SyncButton(
              onSync: () async {
                await RouteRefreshHelper.refreshCurrentPage(
                  ref,
                  context,
                );
              },
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                context.go('/notification');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Badge(
                  alignment: const AlignmentDirectional(0.6, -0.6),
                  smallSize: 7,
                  backgroundColor: Colors.red.shade500,
                  isLabelVisible: ref.watch(notificationNotifierProvider).notifications.isNotEmpty,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref
                      .read(authControllerProvider.notifier)
                      .logout();
                } else if (value == 'profile') {
                  context.go('/profile');
                }
              },
              child: userNameAsync.when(
                data: (name) => CircleAvatar(
                  radius: 16,
                  backgroundColor: primary,
                  child: Text(
                    (name ?? 'U').isNotEmpty ? (name ?? 'U')[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
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
                  child: Text('U',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              itemBuilder: (context) => [
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
      ),
    );
  }

}
