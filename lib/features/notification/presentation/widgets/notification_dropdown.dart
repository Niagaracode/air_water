import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../controller/notification_provider.dart';
import '../model/notification_model.dart';

class NotificationDropdown extends ConsumerStatefulWidget {
  const NotificationDropdown({super.key});

  @override
  ConsumerState<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends ConsumerState<NotificationDropdown> {
  @override
  void initState() {
    super.initState();
    // Refresh data when dropdown is opened
    Future.microtask(() {
      ref.read(notificationNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);

    return Container(
      width: 350,
      constraints: const BoxConstraints(maxHeight: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Flexible(
            child: _buildList(state),
          ),
          const Divider(height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          TextButton(
            onPressed: () {
              // Mark all as read logic can go here
            },
            child: Text(
              'Mark all as read',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (state.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No new notifications',
              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: state.notifications.length > 5 ? 5 : state.notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _buildNotificationItem(context, notification);
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel n) {
    final color = _getImportanceColor(n.importance);

    return InkWell(
      onTap: () {
        // Handle notification click
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(n.parameterType),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.parameterType ?? 'Alert',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(n.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${n.tankNumber ?? 'Tank'} - ${n.ruleName ?? 'Threshold hit'}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go('/notification');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'View all notifications',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  Color _getImportanceColor(String? importance) {
    switch (importance?.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getIcon(String? type) {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('level')) return Icons.water_drop_rounded;
    if (t.contains('bat')) return Icons.battery_alert_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}
