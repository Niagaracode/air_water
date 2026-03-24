import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/asset_schedule_provider.dart';
import '../model/asset_schedule_model.dart';
import '../../../../shared/widgets/app_table.dart';

class AssetScheduleProTable extends ConsumerStatefulWidget {
  const AssetScheduleProTable({super.key});

  @override
  ConsumerState<AssetScheduleProTable> createState() => _AssetScheduleProTableState();
}

class _AssetScheduleProTableState extends ConsumerState<AssetScheduleProTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetScheduleProvider);

    if (state.isLoading && state.schedules.isEmpty) {
      return const AppTableInitialLoader();
    }

    if (state.error != null && state.schedules.isEmpty) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (state.schedules.isEmpty) {
      return const AppTableEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No schedules found',
        subtitle: 'Try adjusting your filters or search criteria.',
      );
    }

    // Grouping schedules by Plant and Tank
    final Map<String, List<AssetScheduleModel>> groupedSchedules = {};
    for (var s in state.schedules) {
      final groupKey = '${s.plantName} - ${s.tankNumber}';
      groupedSchedules.putIfAbsent(groupKey, () => []).add(s);
    }
    final List<String> groupKeys = groupedSchedules.keys.toList();

    // Prepare day headers for forecast (14 days)
    final now = DateTime.now();
    final List<String> dayHeaders = List.generate(14, (index) {
      final date = now.add(Duration(days: index));
      return '${DateFormat('EEE').format(date).toUpperCase()} ${DateFormat('M/d').format(date)}';
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate widths
        const double staticWidth = 70 + 150 + 180 + 150 + 150 + 80;
        final double forecastWidth = dayHeaders.length * 80.0;
        // Include 32px for horizontal padding (16 left + 16 right)
        final double totalWidth = staticWidth + forecastWidth + 32;

        // Use a ScrollController to sync or just let them scroll independently
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(dayHeaders),
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: groupKeys.length + 1,
                        itemBuilder: (context, index) {
                          if (index == groupKeys.length) {
                            return const AppTableBottomCap();
                          }
                          final groupKey = groupKeys[index];
                          final schedules = groupedSchedules[groupKey]!;
                          return _buildGroup(context, groupKey, schedules, index + 1);
                        },
                      ),
                    ),
                  ),
                  if (state.isLoading) const AppTableLoadingMore(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(List<String> dayHeaders) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          const AppTableHeaderCell('SI.NO', width: 70),
          const AppTableHeaderCell('ITEM', width: 150),
          const AppTableHeaderCell('SITE LOCATION', width: 180),
          const AppTableHeaderCell('SCHEDULE REFILL', width: 150),
          const AppTableHeaderCell('RUNOUT DATE', width: 150),
          const AppTableHeaderCell('UNIT', width: 80),
          // Day Headers
          ...dayHeaders.map((h) => AppTableHeaderCell(h, width: 80)),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String groupKey,
    List<AssetScheduleModel> schedules,
    int index,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF), // Blue 50
            border: Border(
              left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
                const Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: Color(0xFF1E40AF),
                ),
                const SizedBox(width: 8),
                Text(
                  groupKey,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    '${schedules.length} ${schedules.length == 1 ? "Item" : "Items"}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Group Rows
        ...schedules.map((schedule) => _buildDataRow(schedule)),
      ],
    );
  }

  Widget _buildDataRow(AssetScheduleModel schedule) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      child: Row(
        children: [
          const AppTableCell(null, width: 70), // SI.NO spacing
          AppTableCell(
            null,
            width: 150,
            child: Row(
              children: [
                Icon(
                  schedule.item.toLowerCase().contains('level')
                      ? Icons.analytics_outlined
                      : schedule.item.toLowerCase().contains('battery')
                          ? Icons.battery_std_outlined
                          : Icons.circle_outlined,
                  size: 16,
                  color: const Color(0xFF141E7A),
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.item,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          AppTableCell(
            schedule.siteLocation,
            width: 180,
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
          AppTableCell(
            null,
            width: 150,
            child: schedule.nextScheduledRefill != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateFormat.format(schedule.nextScheduledRefill!),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        timeFormat.format(schedule.nextScheduledRefill!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '—',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
          ),
          AppTableCell(
            null,
            width: 150,
            child: schedule.runoutDate != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateFormat.format(schedule.runoutDate!),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626), // Red for runout
                        ),
                      ),
                      Text(
                        timeFormat.format(schedule.runoutDate!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  )
                : Text(
                    '—',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
          ),
          AppTableCell(
            schedule.unit,
            width: 80,
            fontSize: 13,
            color: const Color(0xFF4B5563),
          ),
          // Forecast Cells
          ...schedule.forecast.map(
            (f) =>
                AppTableCell(null, width: 80, child: _buildForecastCell(f)),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCell(AssetScheduleForecast forecast) {
    Color barColor = const Color(0xFF10B981); // Emerald 500 (Green - Full)
    if (forecast.status == 'critical') {
      barColor = const Color(0xFFEF4444); // Red 500 (Red - Empty)
    } else if (forecast.status == 'warning') {
      barColor = const Color(0xFFF59E0B); // Amber 500 (Yellow - Warning)
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          forecast.value.toStringAsFixed(0),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: barColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
