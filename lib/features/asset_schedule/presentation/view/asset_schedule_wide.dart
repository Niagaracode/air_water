import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/asset_schedule_provider.dart';
import '../model/asset_schedule_model.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_dropdown.dart';

class AssetScheduleWide extends ConsumerStatefulWidget {
  const AssetScheduleWide({super.key});

  @override
  ConsumerState<AssetScheduleWide> createState() => _AssetScheduleWideState();
}

class _AssetScheduleWideState extends ConsumerState<AssetScheduleWide> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(assetScheduleProvider.notifier).loadData(refresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetScheduleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildFilterBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: state.isLoading && state.schedules.isEmpty
                        ? const AppTableInitialLoader()
                        : _buildVirtualizedTable(state.schedules),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCHEDULE',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor run-out dates and plan future refills across all assets.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(
              'EXPORT SCHEDULE',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAB308),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 200,
            child: AppDropdown<String>(
              value: 'All',
              items: const ['All', '0-5', '6-10', '10+'],
              hint: 'Days to Run Out',
              itemLabel: (v) => v,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: AppDropdown<String>(
              value: 'default',
              items: const ['default', 'liters', 'gallons'],
              hint: 'Units',
              itemLabel: (v) => v,
              onChanged: (_) {},
            ),
          ),
          const Spacer(),
          Text(
            'Showing 1-20 of 85 entries',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(List<AssetScheduleModel> schedules) {
    if (schedules.isEmpty) {
      return const AppTableEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No schedules found',
      );
    }

    // Grouping schedules by plantName
    final Map<String, List<AssetScheduleModel>> groupedSchedules = {};
    for (var s in schedules) {
      groupedSchedules.putIfAbsent(s.plantName, () => []).add(s);
    }
    final List<String> groupNames = groupedSchedules.keys.toList();

    final now = DateTime.now();
    final List<String> dayHeaders = List.generate(10, (index) {
      final date = now.add(Duration(days: index));
      return '${DateFormat('EEE').format(date).toUpperCase()} ${DateFormat('M/d').format(date)}';
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        const double staticWidth = 50 + 150 + 180 + 150 + 150 + 80;
        final double totalWidth = staticWidth + (dayHeaders.length * 80);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                _buildFixedTableHeader(dayHeaders),
                Expanded(
                  child: ListView.builder(
                    itemCount: groupNames.length,
                    itemBuilder: (context, index) {
                      final plantName = groupNames[index];
                      final plantSchedules = groupedSchedules[plantName]!;
                      return _buildGroup(plantName, plantSchedules, index);
                    },
                  ),
                ),
                const AppTableBottomCap(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroup(String plantName, List<AssetScheduleModel> schedules, int groupIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupHeader(plantName, schedules.length, groupIndex + 1),
        ...schedules.asMap().entries.map((entry) {
          final isLastInGroup = entry.key == schedules.length - 1;
          return _buildScheduleRow(entry.value, entry.key, isLastInGroup);
        }),
      ],
    );
  }

  Widget _buildGroupHeader(String plantName, int itemCount, int index) {
    return Container(
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
              width: 50,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.factory_outlined, size: 16, color: Color(0xFF1E40AF)),
                  const SizedBox(width: 8),
                  Text(
                    plantName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '$itemCount ${itemCount == 1 ? "Item" : "Items"}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFixedTableHeader(List<String> dayHeaders) {
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
          const AppTableHeaderCell('SI.NO', width: 50),
          const AppTableHeaderCell('ASSET', width: 150),
          const AppTableHeaderCell('SITE LOCATION', width: 180),
          const AppTableHeaderCell('SCHEDULED REFILL', width: 150),
          const AppTableHeaderCell('RUNOUT DATE', width: 150),
          const AppTableHeaderCell('UNITS', width: 80),
          ...dayHeaders.map((h) => AppTableHeaderCell(h, width: 80)),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    AssetScheduleModel schedule,
    int index,
    bool isLast,
  ) {
    final dateFormat = DateFormat('M/d/yyyy');
    final timeFormat = DateFormat('h:mm a');

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
          AppTableCell((index + 1).toString(), width: 50, fontSize: 13),
          AppTableCell(
            null,
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  schedule.plantName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  schedule.item,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          AppTableCell(schedule.siteLocation, width: 180, fontSize: 13),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeFormat.format(schedule.nextScheduledRefill!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text('—'),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeFormat.format(schedule.runoutDate!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Text('—'),
          ),
          AppTableCell(schedule.unit, width: 80, fontSize: 13),
          ...schedule.forecast.map(
            (f) => AppTableCell(null, width: 80, child: _buildForecastCell(f)),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCell(AssetScheduleForecast forecast) {
    Color barColor = const Color(0xFF10B981); // Emerald 500
    if (forecast.status == 'critical') {
      barColor = const Color(0xFFEF4444); // Red 500
    } else if (forecast.status == 'warning') {
      barColor = const Color(0xFFF59E0B); // Amber 500
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
