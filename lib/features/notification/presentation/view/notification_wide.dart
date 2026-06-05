import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/table_data_cell.dart';
import '../../../../shared/widgets/table_header_cell.dart';
import '../../../../shared/widgets/view_header.dart';
import '../controller/notification_provider.dart';
import '../model/notification_model.dart';

class NotificationWide extends ConsumerStatefulWidget {
  const NotificationWide({super.key});

  @override
  ConsumerState<NotificationWide> createState() => _NotificationWideState();
}

class _NotificationWideState extends ConsumerState<NotificationWide> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildSummaryCards(state.summary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: _buildTableBody(state, notifier),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return const ViewHeader(
      title: 'NOTIFICATIONS',
      subtitle: 'Real-time alerts and system notifications for levels, battery, and critical events.',
      showButton: false,
      showBackButton: true,
    );
  }

  Widget _buildSummaryCards(NotificationSummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          _buildStatCard('Critical Level', summary.criticalLevel, Colors.red),
          const SizedBox(width: 16),
          _buildStatCard('Low Level', summary.lowLevel, Colors.orange),
          const SizedBox(width: 16),
          _buildStatCard('Low Battery', summary.lowBattery, Colors.amber),
          const SizedBox(width: 16),
          _buildStatCard('Total Alerts', summary.total, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableBody(NotificationState state, NotificationNotifier notifier) {
    if (state.notifications.isEmpty && !state.isLoading) {
      return const AppTableEmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'No notifications found',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        dataRowHeight: 55,
        headingRowHeight: 45,
        headingRowColor: WidgetStateProperty.all(primary.withValues(alpha: 0.05)),
        dividerThickness: 0.4,
        columns: const [
          DataColumn2(label: TableHeaderCell(label: 'Timestamp'), size: ColumnSize.M),
          DataColumn2(label: TableHeaderCell(label: 'Type'), size: ColumnSize.S),
          DataColumn2(label: TableHeaderCell(label: 'Tank/Site'), size: ColumnSize.L),
          DataColumn2(label: TableHeaderCell(label: 'Rule'), size: ColumnSize.M),
          DataColumn2(label: TableHeaderCell(label: 'Value'), size: ColumnSize.S),
          DataColumn2(label: TableHeaderCell(label: 'Importance'), fixedWidth: 100),
          DataColumn2(label: TableHeaderCell(label: 'Company'), size: ColumnSize.M),
          DataColumn2(label: TableHeaderCell(label: 'Subject'), size: ColumnSize.L),
          DataColumn2(label: TableHeaderCell(label: 'Description'), size: ColumnSize.L),
        ],
        rows: state.notifications.map((n) {
          final color = _getImportanceColor(n.importance);
          return DataRow(
            cells: [
              DataCell(TableDataCell(label: _formatDate(n.createdAt))),
              DataCell(TableDataCell(label: n.parameterType ?? '—', bold: true)),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.tankNumber ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(n.plantName ?? '', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              )),
              DataCell(TableDataCell(label: n.ruleName ?? '—')),
              DataCell(TableDataCell(label: n.value?.toString() ?? '—')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  n.importance?.toUpperCase() ?? 'WARNING',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              )),
              DataCell(TableDataCell(label: n.companyName ?? '—')),
              DataCell(Text(
                n.subject ?? '—',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )),
              DataCell(Text(
                n.body ?? '—',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getImportanceColor(String? importance) {
    switch (importance?.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
      case 'reorder':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
