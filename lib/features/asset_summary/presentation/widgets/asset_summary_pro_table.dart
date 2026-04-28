import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../controller/asset_summary_provider.dart';
import '../model/asset_summary_model.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../user/presentation/controller/user_provider.dart';

// Asset Summary Table with virtualization and data isolation
class AssetSummaryProTable extends ConsumerWidget {
  final Function(int index)? onGroupTap;

  const AssetSummaryProTable({super.key, this.onGroupTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assetSummaryProvider);

    if (state.isLoading && state.groups.isEmpty) {
      return const AppTableInitialLoader();
    }

    if (state.error != null && state.groups.isEmpty) {
      return Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)));
    }

    final userState = ref.watch(userProvider);
    final currentUser = userState.currentUser;
    final isCustomer = currentUser?.roleId == 6;

    if (state.groups.isEmpty) {
      if (isCustomer) {
        return _buildCustomerEmptyState(currentUser);
      }
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
                        onTap: () {
                          if (onGroupTap != null) {
                            onGroupTap!(index - 1);
                          } else {
                            context.push('/tank/details/${group.tankId}');
                          }
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E40AF),
                            ),
                            children: [
                              TextSpan(text: group.plantName.isEmpty ? 'Unknown Site' : group.plantName),
                              if (group.companyName != null && group.companyName!.isNotEmpty) ...[
                                TextSpan(
                                  text: ' [${group.companyName}]',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ] else ...[
                                TextSpan(
                                  text: ' [No Company]',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              TextSpan(text: ' - ${group.tankNumber}'),
                            ],
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

  Widget _buildCustomerEmptyState(User? user) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 24),
          Text(
            'No active assets found for your account',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account is correctly configured with the following assignments:',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          _buildAssignmentRow(Icons.business_outlined, 'Company', user?.companyName ?? '[No Company Assigned]'),
          const Divider(height: 24),
          _buildAssignmentRow(
            Icons.location_on_outlined, 
            'Assigned Sites', 
            (user?.assignedSites?.isEmpty ?? true) 
              ? 'None direct (Inherited from Company)' 
              : user?.assignedSites?.map((s) => s.name).join(', ') ?? ''
          ),
          const Divider(height: 24),
          _buildAssignmentRow(
            Icons.inventory_2_outlined, 
            'Assigned Tanks', 
            (user?.assignedTanks?.isEmpty ?? true) 
              ? 'None direct (Check with Admin)' 
              : '${user?.assignedTanks?.length ?? 0} Specific Tanks'
          ),
          const SizedBox(height: 40),
          Text(
            'If you expect to see assets here, please contact your Super Admin to ensure your Company or User is linked to the correct Sites and Tanks in the database.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF141E7A)),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
