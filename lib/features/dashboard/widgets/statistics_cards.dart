import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsCards extends StatelessWidget {
  const StatisticsCards({
    super.key,
    required this.statistics,
  });

  final Map<String, dynamic> statistics;

  static const double _narrowBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final total = statistics['total'] ?? 0;
    final active = statistics['online'] ?? 0;
    final offline = statistics['offline'] ?? 0;
    final lowBattery = statistics['lowBattery'] ?? 0;
    final lowLevel = statistics['lowLevel'] ?? 0;
    final reorderLevel = statistics['reorder'] ?? 0;

    final items = [
      _StatData(
        title: 'Active Devices',
        subtitle: 'Online',
        value: active,
        total: total,
        color: Colors.green,
        icon: Icons.devices,
        gradient: const LinearGradient(
          colors: [Color(0xFFA7F3D0), Color(0xFF6EE7B7)],
        ),
      ),
      _StatData(
        title: 'Offline Devices',
        subtitle: 'Offline',
        value: offline,
        total: total,
        color: Colors.grey,
        icon: Icons.offline_bolt,
        gradient: const LinearGradient(
          colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
        ),
      ),
      _StatData(
        title: 'Low Batt/Solar',
        subtitle: 'Needs Charging',
        value: lowBattery,
        total: total,
        color: Colors.yellow,
        icon: Icons.battery_alert,
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)],
        ),
      ),
      _StatData(
        title: 'Low Level',
        subtitle: 'Below Threshold',
        value: lowLevel,
        total: total,
        color: Colors.orange,
        icon: Icons.water_drop,
        gradient: const LinearGradient(
          colors: [Color(0xFFFED7AA), Color(0xFFF97316)],
        ),
      ),
      _StatData(
        title: 'Reorder Level',
        subtitle: 'Need Restock',
        value: reorderLevel,
        total: total,
        color: Colors.amber,
        icon: Icons.inventory,
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < _narrowBreakpoint;

        if (!isNarrow) {
          // Unchanged wide/tablet behavior.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  StatusChip(data: items[i]),
                  if (i != items.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
          );
        }

        // Narrow/mobile: compact 2-column grid of self-contained stat tiles
        // instead of a wide, partially-hidden horizontal scroller.
        final columns = constraints.maxWidth < 340 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.6 : 2.95,
          ),
          itemBuilder: (context, index) => CompactStatCard(data: items[index]),
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.total,
    required this.color,
    required this.gradient,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final int value;
  final int total;
  final Color color;
  final Gradient gradient;
  final IconData icon;
}

/// Original wide-layout chip: icon, title/subtitle, then big value - all in
/// one row. Used for tablet/desktop widths, unchanged from before.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.data,
    this.iconBackgroundOpacity = 0.2,
    this.textColorOpacity = 0.7,
  });

  final _StatData data;
  final double iconBackgroundOpacity;
  final double textColorOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: data.gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.3),
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
              data.icon,
              color: Colors.black.withValues(alpha: textColorOpacity),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: textColorOpacity),
                ),
              ),
              Text(
                data.subtitle,
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
                '${data.value}',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: textColorOpacity),
                ),
              ),
              Text(
                'of ${data.total}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.5),
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

/// Compact stat tile for narrow/mobile screens: icon top-left, big value
/// top-right, title/subtitle below, and a thin proportion bar footer
/// (value out of total) as a quick visual cue. Designed to sit in a
/// 2-column grid so every metric is visible at once without side-scrolling.
class CompactStatCard extends StatelessWidget {
  const CompactStatCard({
    super.key,
    required this.data,
    this.iconBackgroundOpacity = 0.22,
    this.textColorOpacity = 0.72,
  });

  final _StatData data;
  final double iconBackgroundOpacity;
  final double textColorOpacity;

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        gradient: data.gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: iconBackgroundOpacity),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              data.icon,
              color: Colors.black.withValues(alpha: textColorOpacity),
              size: 16,
            ),
          ),
          SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: textColorOpacity),
                ),
              ),
              Text(
                '${data.subtitle} \u00b7 of ${data.total}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${data.value}',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: textColorOpacity),
            ),
          ),
        ],
      ),
    );
  }
}