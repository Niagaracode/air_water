import 'package:air_water/features/dashboard/presentation/widgets/sync_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../provider/dashboard_provider.dart';
import 'mqtt_connection_status.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.value ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E7A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_tethering,
                          size: 12,
                          color: const Color(0xFF141E7A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Monitor your tank levels in real-time',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF141E7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                SyncButton(
                  onSync: () async {
                    await _refreshData(ref, context);
                  },
                ),
                const SizedBox(width: 16),
                const MqttConnectionStatus(),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Helper function to refresh data
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