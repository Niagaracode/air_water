import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../presentation/controller/alarm_provider.dart';
import '../presentation/model/alarm_model.dart';

class AlarmWide extends ConsumerStatefulWidget {
  const AlarmWide({super.key});

  @override
  ConsumerState<AlarmWide> createState() => _AlarmWideState();
}

class _AlarmWideState extends ConsumerState<AlarmWide> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(alarmProvider.notifier).loadAlarms());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alarmProvider);

    return Scaffold(
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(state)),
              if (state.alarms.isEmpty && !state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: AppTableEmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'No active alarms found',
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverToBoxAdapter(child: _buildTableHeader()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final alarm = state.alarms[index];
                        return _buildAlarmRow(alarm);
                      },
                      childCount: state.alarms.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
          if (state.isLoading) const AppLoader(message: 'Loading Alarms...'),
        ],
      ),
    );
  }

  Widget _buildHeader(AlarmState state) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALARM HISTORY',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time list of triggered alarms and notification events.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(alarmProvider.notifier).loadAlarms(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'REFRESH',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          AppTableHeaderCell('Triggered At', flex: 3),
          const SizedBox(width: 16),
          AppTableHeaderCell('Rule / Site', flex: 5),
          const SizedBox(width: 16),
          AppTableHeaderCell('Parameter', flex: 3),
          const SizedBox(width: 16),
          AppTableHeaderCell('Condition / Value', flex: 4),
          const SizedBox(width: 16),
          AppTableHeaderCell('Status Label', width: 100),
          const SizedBox(width: 16),
          AppTableHeaderCell('Status', width: 80),
        ],
      ),
    );
  }

  Widget _buildAlarmRow(Alarm alarm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Time
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(alarm.triggeredAt),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  _formatDate(alarm.triggeredAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Rule / Tank
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.ruleName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF141E7A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alarm.plantName} • ${alarm.tankNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Parameter
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                alarm.parameterType,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Condition
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Value: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${alarm.currentValue}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _getSeverityColor(alarm.importance),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rule: ${alarm.conditionType} ${alarm.threshold1}${alarm.conditionType == 'BETWEEN' ? ' to ${alarm.threshold2}' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF4B5563),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Importance
          SizedBox(
            width: 100,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(alarm.importance).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getSeverityColor(alarm.importance).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  alarm.importance.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _getSeverityColor(alarm.importance),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status
          SizedBox(
            width: 80,
            child: Center(
              child: AppStatusBadge(status: alarm.status == 'Active' ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _getSeverityColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626); // Red
      case 'medium':
        return const Color(0xFFD97706); // Amber
      case 'low':
        return const Color(0xFF0284C7); // Blue
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
