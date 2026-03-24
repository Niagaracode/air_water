import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../controller/asset_summary_provider.dart';
import '../model/asset_summary_model.dart';
import '../../../../shared/widgets/app_table.dart';

class AssetSummaryProTable extends ConsumerWidget {
  const AssetSummaryProTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assetSummaryProvider);

    if (state.isLoading && state.groups.isEmpty) {
      return const AppTableInitialLoader();
    }

    if (state.error != null && state.groups.isEmpty) {
      return Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)));
    }

    if (state.groups.isEmpty) {
      return const AppTableEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No assets found',
        subtitle: 'Try adjusting your filters or search criteria.',
      );
    }

    return Column(
      children: [
        _buildHeaderRow(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.groups.length,
          itemBuilder: (context, index) {
            final group = state.groups[index];
            return _buildGroup(context, group, index + 1);
          },
        ),
        const AppTableBottomCap(),
        if (state.isLoading) const AppTableLoadingMore(),
        if (state.page < state.totalPages)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: ElevatedButton(
                onPressed: () => ref.read(assetSummaryProvider.notifier).nextPage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('LOAD MORE'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderRow() {
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
      child: const Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 70),
          AppTableHeaderCell('ITEM', flex: 2),
          AppTableHeaderCell('READING TIME', flex: 2),
          AppTableHeaderCell('READING VALUE', flex: 1),
          AppTableHeaderCell('PRODUCT', flex: 1),
          AppTableHeaderCell('IMPORTANCE', flex: 1),
          AppTableHeaderCell('ROSTER', flex: 2),
          AppTableHeaderCell('ALARM LEVELS', flex: 2),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, AssetSummaryGroup group, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header (Matching Plant style)
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.factory_outlined, size: 16, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => context.push('/tank/details/${group.tankId}'),
                        child: Text(
                          '${group.plantName} - ${group.tankNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E40AF),
                          ),
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
                          '${group.readings.length} ${group.readings.length == 1 ? "Item" : "Items"}',
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
        ),
        // Group Rows
        ...group.readings.map((reading) => _buildDataRow(reading)),
      ],
    );
  }

  Widget _buildDataRow(AssetSummaryReading reading) {
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
          AppTableCell(reading.item, flex: 2, bold: true, fontSize: 13),
          AppTableCell(
            DateFormat('yyyy-MM-dd HH:mm').format(reading.readingTime),
            flex: 2,
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
          AppTableCell(
            reading.readingValue,
            flex: 1,
            bold: true,
            fontSize: 14,
            color: const Color(0xFF2563EB),
          ),
          AppTableCell(reading.product, flex: 1, fontSize: 13),
          _buildImportanceCell(reading.importance, 1),
          AppTableCell(
            reading.rosterName ?? '—', 
            flex: 2, 
            fontSize: 12, 
            color: const Color(0xFF4B5563)
          ),
          AppTableCell(
            reading.alarmLevels, 
            flex: 2, 
            fontSize: 12, 
            color: const Color(0xFF9CA3AF)
          ),
        ],
      ),
    );
  }

  Widget _buildImportanceCell(String importance, int flex) {
    final isHigh = importance.toLowerCase() == 'high' || importance.toLowerCase() == 'critical';
    final isMedium = importance.toLowerCase() == 'medium' || importance.toLowerCase() == 'warning';
    
    final color = isHigh ? const Color(0xFFDC2626) : (isMedium ? const Color(0xFFD97706) : const Color(0xFF059669));
    final bg = isHigh ? const Color(0xFFFEF2F2) : (isMedium ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5));
    final label = importance.toUpperCase();

    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
