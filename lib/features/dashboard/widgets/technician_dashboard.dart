import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/alarm/presentation/controller/alarm_provider.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import 'dashboard_summary_card.dart';

class TechnicianDashboard extends ConsumerWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmState = ref.watch(alarmProvider);
    final tankState = ref.watch(tankNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(alarmState, tankState),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildActiveAlarmsCard(alarmState),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 2,
              child: _buildAssetSummaryCard(tankState),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(AlarmState alarmState, TankState tankState) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 64) / 3;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: cardWidth,
            child: DashboardSummaryCard(
              title: 'Active Alarms',
              value: '${alarmState.alarms.length}',
              icon: Icons.notifications_active_rounded,
              type: SummaryCardType.danger,
              subtitle: 'Requires Attention',
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: DashboardSummaryCard(
              title: 'Assigned Tanks',
              value: '${tankState.totalEntries}',
              icon: Icons.storage_rounded,
              type: SummaryCardType.info,
              subtitle: 'Total Capacity Monitoring',
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: const DashboardSummaryCard(
              title: 'System Health',
              value: '98%',
              icon: Icons.health_and_safety_rounded,
              type: SummaryCardType.success,
              subtitle: 'Optimal Performance',
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActiveAlarmsCard(AlarmState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE ALARMS',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                'Show All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.alarms.isEmpty)
            _buildEmptyState('No active alarms', Icons.notifications_off_rounded)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.alarms.length > 5 ? 5 : state.alarms.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final alarm = state.alarms[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: alarm.importance.toLowerCase() == 'high' 
                          ? const Color(0xFFFEF2F2) 
                          : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: alarm.importance.toLowerCase() == 'high' 
                          ? const Color(0xFFDC2626) 
                          : const Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.ruleName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '${alarm.plantName} • ${alarm.tankNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTriggerTime(alarm.triggeredAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAssetSummaryCard(TankState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSET STATUS',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.groupedTanks.isEmpty)
            _buildEmptyState('No assets found', Icons.storage_rounded)
          else
            _buildAssetList(state),
        ],
      ),
    );
  }

  Widget _buildAssetList(TankState state) {
    final List<dynamic> allTanks = [];
    for (var group in state.groupedTanks) {
      allTanks.addAll(group.tanks);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allTanks.length > 6 ? 6 : allTanks.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final tank = allTanks[index];
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tank.tankNumber,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    tank.productName ?? 'No Product',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tank.status == 1 ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tank.status == 1 ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tank.status == 1 ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTriggerTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
