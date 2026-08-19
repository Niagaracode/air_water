import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controller/asset_schedule_provider.dart';
import '../widgets/asset_schedule_pro_table.dart';
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
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
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
                        : const AssetScheduleProTable(),
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
            onPressed: () {
              ref.read(assetScheduleProvider.notifier).loadData(refresh: true);
            },
            icon: const Icon(Icons.refresh_outlined, size: 18),
            label: Text(
              'REFRESH',
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
    final state = ref.watch(assetScheduleProvider);
    final selectedDate = state.startDate ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFFEAB308),
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF111827),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                ref.read(assetScheduleProvider.notifier).loadData(startDate: date);
              }
            },
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFEAB308)),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF9CA3AF)),
                ],
              ),
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
}
