import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme/app_theme.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';


import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';

class ScreenHeader extends ConsumerWidget {
  const ScreenHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);
    final roleAsync = ref.watch(userRoleProvider);
    
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

              /// ── Search bar ────────────────────────────────────
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                    ),
                    child: TextField(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search anything...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

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

              const SizedBox(width: 12),

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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      userNameAsync.when(
                        data: (name) => CircleAvatar(
                          radius: 16,
                          backgroundColor: primary,
                          child: Text(
                            (name ?? 'U').isNotEmpty
                                ? (name ?? 'U')[0].toUpperCase()
                                : 'U',
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
                      const SizedBox(width: 10),
                      userNameAsync.when(
                        data: (name) => Text(
                          name ?? 'User',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        loading: () => Text(
                          'Loading...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        error: (_, __) => Text(
                          'User',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
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
            ],
          ),
        ),
      ),
    );
  }
}
