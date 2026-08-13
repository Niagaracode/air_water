import 'package:air_water/layout/widgets/sidebar_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../core/app_theme/app_theme.dart';
import '../../core/helpers/route_refresh_helper.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';

import '../../core/user_config/user_role.dart';
import '../../features/dashboard/widgets/mqtt_connection_status.dart';
import '../../features/dashboard/widgets/sync_button.dart';
import '../../features/notification/presentation/widgets/notification_dropdown.dart';
import '../../features/notification/presentation/controller/notification_provider.dart';
import '../provider/search_provider.dart';
import '../provider/sidebar_provider.dart';
import '../../features/user/presentation/controller/user_provider.dart';
import 'package:debounce_throttle/debounce_throttle.dart';


class ScreenHeader extends ConsumerStatefulWidget {
  const ScreenHeader({super.key, required this.userRole});
  final UserRole userRole;

  @override
  ConsumerState<ScreenHeader> createState() => _ScreenHeaderState();
}

class _ScreenHeaderState extends ConsumerState<ScreenHeader> {
  late final TextEditingController _searchController;
  late final Debouncer<String> _debouncer;
  late final FocusNode _searchFocusNode;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
    _debouncer = Debouncer<String>(
      const Duration(milliseconds: 400),
      initialValue: '',
      checkEquality: true,
    );
    _debouncer.values.listen((value) {
      if (mounted) {
        ref.read(globalSearchProvider.notifier).state = value;
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debouncer.setValue('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.value ?? 'User';
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final userState = ref.watch(userProvider);
    final currentUser = userState.currentUser;
    final displayName = currentUser != null
        ? '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim()
        : '';
    final finalDisplayName = displayName.isNotEmpty ? displayName : userName;

    return SizedBox(
      height: 65,
      width: double.infinity,
      child: Card(
        color: Colors.white,
        surfaceTintColor: primary,
        shadowColor: primary.withValues(alpha: 0.2),
        margin: EdgeInsets.zero,
        elevation: 1.2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.zero),
        ),
        child: Row(
          children: [
            SidebarHeader(isExpanded: isExpanded, userRole: widget.userRole),
            const SizedBox(width: 16),
            Text(
              '${AppConfig.current.appName} welcomes, $finalDisplayName!',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isSearchFocused ? Colors.white
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isSearchFocused
                          ? primary.withValues(alpha: 0.3)
                          : Colors.black12,
                      width: 1,
                    ),
                    boxShadow: _isSearchFocused ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.02),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                        : null,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _debouncer.setValue,
                    textAlignVertical: TextAlignVertical.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF3C4043),
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: 'Search anything...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF9AA0A6),
                        fontSize: 13.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.black54,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 36,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF9AA0A6),
                            ),
                            onPressed: _clearSearch,
                          );
                        },
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const MqttConnectionStatus(),
            const SizedBox(width: 16),
            SyncButton(
              browserStyle: true,
              onSync: () async {
                await RouteRefreshHelper.refreshCurrentPage(ref, context);
              },
            ),
            const SizedBox(width: 16),
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
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
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
            const SizedBox(width: 16),
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
      ),
    );
  }
}