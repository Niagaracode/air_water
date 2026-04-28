import 'package:air_water/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class StatisticsCards extends StatelessWidget {
  const StatisticsCards({
    super.key,
    required this.statistics,
  });

  final Map<String, dynamic> statistics;

  @override
  Widget build(BuildContext context) {
    final total = statistics['total'] ?? 0;
    final active = statistics['active'] ?? 0;
    final offline = statistics['offline'] ?? 0;
    final lowBattery = statistics['lowBattery'] ?? 0;
    final lowLevel = statistics['lowLevel'] ?? 0;
    final reorderLevel = statistics['reorder'] ?? 0;

    return Row(
      children: [
        // Active Devices - Soft Green
        StatCard(
          title: 'Active Devices',
          value: '$active/$total',
          subtitle: 'Online',
          icon: Icons.devices,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFA7F3D0),
              Color(0xFF6EE7B7),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Offline Devices - Soft Gray
        StatCard(
          title: 'Offline Devices',
          value: '$offline/$total',
          subtitle: 'Offline',
          icon: Icons.offline_bolt,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD1D5DB),
              Color(0xFF9CA3AF),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Low Battery - Soft Yellow
        StatCard(
          title: 'Low Battery',
          value: '$lowBattery/$total',
          subtitle: 'Needs Charging',
          icon: Icons.battery_alert,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFDE68A),
              Color(0xFFFBBF24),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Low Level - Soft Orange
        StatCard(
          title: 'Low Level',
          value: '$lowLevel/$total',
          subtitle: 'Below Threshold',
          icon: Icons.water_drop,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFED7AA),
              Color(0xFFF97316),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Reorder Level - Soft Amber
        StatCard(
          title: 'Reorder Level',
          value: '$reorderLevel/$total',
          subtitle: 'Need Restock',
          icon: Icons.inventory,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFEF3C7),
              Color(0xFFFBBF24),
            ],
          ),
        ),
      ],
    );
  }
}