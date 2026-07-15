import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsCards extends StatelessWidget {
  const StatisticsCards({
    super.key,
    required this.statistics,
  });

  final Map<String, dynamic> statistics;

  @override
  Widget build(BuildContext context) {
    final total = statistics['total'] ?? 0;
    final active = statistics['online'] ?? 0;
    final offline = statistics['offline'] ?? 0;
    final lowBattery = statistics['lowBattery'] ?? 0;
    final lowLevel = statistics['lowLevel'] ?? 0;
    final reorderLevel = statistics['reorder'] ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Active Devices - Soft Green
          StatusChip(title: 'Active Devices', value: active, color: Colors.green,
            icon: Icons.devices, gradient: const LinearGradient(
              colors: [
                Color(0xFFA7F3D0),
                Color(0xFF6EE7B7),
              ],
            ), subtitle: 'Online', total: total,),
          const SizedBox(width: 16),
      
          // Offline Devices - Soft Gray
          StatusChip(title: 'Offline Devices', value: offline, color: Colors.grey,
            icon: Icons.offline_bolt, gradient: const LinearGradient(
                colors: [
                  Color(0xFFD1D5DB),
                  Color(0xFF9CA3AF),
                ],
              ), subtitle: 'Offline', total: total,),
          const SizedBox(width: 16),
      
          // Low Battery - Soft Yellow
          StatusChip(title: 'Low Batt/Solar', value: lowBattery, color: Colors.yellow,
            icon: Icons.battery_alert, gradient: const LinearGradient(
                colors: [
                  Color(0xFFFDE68A),
                  Color(0xFFFBBF24),
                ],
              ), subtitle: 'Needs Charging', total: total,),
          const SizedBox(width: 16),
      
          // Low Level - Soft Orange
          StatusChip(title: 'Low Level', value: lowLevel, color: Colors.orange,
            icon: Icons.water_drop, gradient: const LinearGradient(
                colors: [
                  Color(0xFFFED7AA),
                  Color(0xFFF97316),
                ],
              ), subtitle: 'Below Threshold', total: total,),
          const SizedBox(width: 16),
      
          // Reorder Level - Soft Amber
          StatusChip(title: 'Reorder Level', value: reorderLevel, color: Colors.amber,
            icon: Icons.inventory, gradient: const LinearGradient(
                colors: [
                  Color(0xFFFEF3C7),
                  Color(0xFFFBBF24),
                ],
              ), subtitle: 'Need Restock', total: total,),
      
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int total;
  final Color color;
  final Gradient gradient;
  final IconData icon;
  final double iconBackgroundOpacity;
  final double textColorOpacity;

  const StatusChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.total,
    required this.color,
    required this.gradient,
    required this.icon,
    this.iconBackgroundOpacity = 0.2,
    this.textColorOpacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (color).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: iconBackgroundOpacity),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.black.withValues(alpha: textColorOpacity),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: textColorOpacity),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: textColorOpacity),
                ),
              ),
            ],
          ),
          const SizedBox(width: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Text(
                '$value',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(
                    alpha: textColorOpacity,
                  ),
                ),
              ),

              Text(
                'of $total',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

}