import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme/app_theme.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';


import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import '../../features/dashboard/presentation/widgets/mqtt_connection_status.dart';
import '../../features/dashboard/presentation/widgets/sync_button.dart';
import '../../features/dashboard/provider/dashboard_provider.dart';

class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final userName = userNameAsync.value ?? 'User';
    
    final isCustomer = roleAsync.when(
      data: (role) => role == UserRole.customer,
      loading: () => false,
      error: (_, __) => false,
    );

    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.black.withValues(alpha: 0.15), width: 1),
            ),
          ),
          child: Row(
            children: [

              Text(
                'Welcome back, $userName!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black45,
                ),
              ),

              const Spacer(),

              const MqttConnectionStatus(),
              const SizedBox(width: 16),

              SyncButton(
                onSync: () async {
                  await _refreshData(ref, context);
                },
              ),
              const SizedBox(width: 16),

              /// ── Notification icon ────────────────────────────
              Container(
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
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              /// ── User menu ─────────────────────────────────────
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
                  if (!isCustomer) ...[
                    PopupMenuItem(
                      value: 'profile',
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: Color(0xFF374151),
                          ),
                        ),
                        title: Text(
                          'Profile',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ),
                    const PopupMenuDivider(height: 4),
                  ],
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
      ),
    );
  }

  Future<void> _refreshData(WidgetRef ref, BuildContext context) async {
    try {
      // Refresh the tank data from server
      await ref.read(tankDataListProvider.notifier).refresh();

      // Invalidate related providers to refresh UI
      ref.invalidate(tankStatisticsProvider);
      ref.invalidate(groupedTanksProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Data synced successfully!',
                  style: GoogleFonts.outfit(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to sync: ${e.toString()}',
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
