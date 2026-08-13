import 'dart:typed_data';
import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_saver/file_saver.dart';
import 'package:air_water/features/site/presentation/model/site_model.dart';
import 'package:air_water/features/device/presentation/controller/device_provider.dart';
import 'package:air_water/features/user/presentation/controller/user_provider.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/table_data_cell.dart';
import '../../../../shared/widgets/table_header_cell.dart';
import '../../../../shared/widgets/view_header.dart';
import '../controller/notification_provider.dart';
import '../model/notification_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../../core/user_config/user_role.dart';

class NotificationWide extends ConsumerStatefulWidget {
  const NotificationWide({super.key});

  @override
  ConsumerState<NotificationWide> createState() => _NotificationWideState();
}

class _NotificationWideState extends ConsumerState<NotificationWide> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);
    final userRole = ref.watch(userRoleProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildSummaryCards(state.summary),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12.0 : 24.0,
                      vertical: 8.0,
                    ),
                    child: isMobile
                        ? ListView.builder(
                            controller: _scrollController,
                            itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.notifications.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildMobileEventCard(state.notifications[index]);
                            },
                          )
                        : _buildTableBody(state, notifier, userRole),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final userRole = ref.watch(userRoleProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final headerText = ViewHeader(
      title: 'EVENTS',
      subtitle:
          'Real-time alerts and system notifications for levels, battery, and critical events.',
      showButton: false,
      showBackButton: userRole == UserRole.customer,
      onBack: () => context.go('/dashboard'),
    );

    final downloadButton = PopupMenuButton<String>(
      tooltip: 'Download Report',
      onSelected: (value) {
        _showDateRangeDownloadDialog(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, color: primary),
              const SizedBox(width: 10),
              Text(
                'Download Excel',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: primary),
              const SizedBox(width: 10),
              Text(
                'Download PDF',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(
              'Download',
              style: GoogleFonts.inter(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'EVENTS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                downloadButton,
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time alerts and system notifications for levels, battery, and critical events.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: headerText,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              downloadButton,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(NotificationSummary summary) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard('Critical Level', summary.criticalLevel, Colors.red),
                const SizedBox(width: 12),
                _buildStatCard('Low Level', summary.lowLevel, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('Low Battery', summary.lowBattery, Colors.amber),
                const SizedBox(width: 12),
                _buildStatCard('Total Alerts', summary.total, Colors.blue),
              ],
            ),
          ],
        ),
      );
    }

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildMobileEventCard(NotificationModel n) {
    final color = _getImportanceColor(n.importance);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Text(
                  n.importance?.toUpperCase() ?? 'WARNING',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                _formatDate(n.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            n.subject ?? '—',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          if (n.body != null && n.body!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              n.body!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANK / SITE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.tankNumber ?? 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    if (n.plantName != null && n.plantName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.plantName!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFE5E7EB),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TYPE & VALUE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        n.parameterType ?? '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      if (n.value != null) ...[
                        Text(
                          ' (${n.value})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(
    NotificationState state,
    NotificationNotifier notifier,
    UserRole? userRole,
  ) {
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
        scrollController: _scrollController,
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        dataRowHeight: 55,
        headingRowHeight: 45,
        headingRowColor: WidgetStateProperty.all(
          primary.withValues(alpha: 0.05),
        ),
        dividerThickness: 0.4,
        columns: [
          const DataColumn2(
            label: TableHeaderCell(label: 'Last Updated'),
            size: ColumnSize.M,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Type'),
            size: ColumnSize.S,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Tank/Site'),
            size: ColumnSize.L,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Message'),
            size: ColumnSize.M,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Value'),
            size: ColumnSize.S,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Importance'),
            fixedWidth: 100,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Subject'),
            size: ColumnSize.L,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Description'),
            size: ColumnSize.L,
          ),
        ],
        rows: [
          ...state.notifications.map((n) {
            final color = _getImportanceColor(n.importance);
            return DataRow(
              cells: [
                DataCell(TableDataCell(label: _formatDate(n.createdAt))),
                DataCell(
                  TableDataCell(label: n.parameterType ?? '—', bold: true),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.tankNumber ?? 'N/A',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        n.plantName ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(TableDataCell(label: n.ruleName ?? '—')),
                DataCell(TableDataCell(label: n.value?.toString() ?? '—')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      n.importance?.toUpperCase() ?? 'WARNING',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    n.subject ?? '—',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text(
                    n.body ?? '—',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
          if (state.hasMore)
            DataRow(
              cells: [
                const DataCell(
                  Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF141E7A),
                      ),
                    ),
                  ),
                ),
                const DataCell(SizedBox.shrink()),
                const DataCell(SizedBox.shrink()),
                const DataCell(SizedBox.shrink()),
                const DataCell(SizedBox.shrink()),
                const DataCell(SizedBox.shrink()),

                const DataCell(SizedBox.shrink()),
                const DataCell(SizedBox.shrink()),
              ],
            ),
        ],
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
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTimeForBackend(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  void _showDateRangeDownloadDialog(String type) {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);

    String errorMessage = '';
    bool isDownloading = false;

    List<SiteAutocompleteInfo> siteList = [];
    List<Map<String, dynamic>> tankList = [];
    SiteAutocompleteInfo? selectedSite;
    Map<String, dynamic>? selectedTank;

    bool isLoadingSites = true;
    bool isLoadingTanks = false;

    bool isValidRange() {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endTime.hour,
        endTime.minute,
      );

      if (startDateTime.isAfter(endDateTime)) {
        errorMessage = 'Start date/time must be before end date/time';
        return false;
      }

      final startDateOnly = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      if (startDateOnly.isAfter(todayDate)) {
        errorMessage = 'Start date cannot be in the future';
        return false;
      }

      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      if (endDateOnly.isAfter(todayDate)) {
        errorMessage = 'End date cannot be in the future';
        return false;
      }

      errorMessage = '';
      return true;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) {
          Future<void> fetchTanks(int? siteId) async {
            dialogSetState(() {
              isLoadingTanks = true;
              tankList = [];
              selectedTank = null;
            });
            try {
              final tanks = await ref
                  .read(deviceApiProvider)
                  .searchTanks('', siteId: siteId);
              dialogSetState(() {
                tankList = tanks;
                isLoadingTanks = false;
              });
            } catch (e) {
              dialogSetState(() {
                isLoadingTanks = false;
              });
            }
          }

          if (isLoadingSites && siteList.isEmpty) {
            Future.microtask(() async {
              try {
                final sites = await ref
                    .read(userRepositoryProvider)
                    .searchSites('');
                dialogSetState(() {
                  siteList = sites;
                  isLoadingSites = false;
                });
              } catch (e) {
                dialogSetState(() {
                  isLoadingSites = false;
                });
              }
            });
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        'Download ${type == 'excel' ? 'Excel' : 'PDF'} Report',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF141E7A),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  Row(
                    children: [
                      // From Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: isDownloading
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: dialogContext,
                                        initialDate: startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        dialogSetState(() {
                                          startDate = date;
                                          isValidRange();
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: errorMessage.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                    width: errorMessage.isNotEmpty ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: errorMessage.isNotEmpty
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${startDate.day}/${startDate.month}/${startDate.year}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: errorMessage.isNotEmpty
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // From Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: isDownloading
                                  ? null
                                  : () async {
                                      final time = await showTimePicker(
                                        context: dialogContext,
                                        initialTime: startTime,
                                      );
                                      if (time != null) {
                                        dialogSetState(() {
                                          startTime = time;
                                          isValidRange();
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: errorMessage.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                    width: errorMessage.isNotEmpty ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: errorMessage.isNotEmpty
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        startTime.format(dialogContext),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: errorMessage.isNotEmpty
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // To Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: isDownloading
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: dialogContext,
                                        initialDate: endDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        dialogSetState(() {
                                          endDate = date;
                                          isValidRange();
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: errorMessage.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                    width: errorMessage.isNotEmpty ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: errorMessage.isNotEmpty
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${endDate.day}/${endDate.month}/${endDate.year}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: errorMessage.isNotEmpty
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // To Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: isDownloading
                                  ? null
                                  : () async {
                                      final time = await showTimePicker(
                                        context: dialogContext,
                                        initialTime: endTime,
                                      );
                                      if (time != null) {
                                        dialogSetState(() {
                                          endTime = time;
                                          isValidRange();
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: errorMessage.isNotEmpty
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                    width: errorMessage.isNotEmpty ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: errorMessage.isNotEmpty
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        endTime.format(dialogContext),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: errorMessage.isNotEmpty
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Site Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Site Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            isLoadingSites
                                ? const SizedBox(
                                    height: 38,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    height: 38,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child:
                                          DropdownButton<SiteAutocompleteInfo?>(
                                            value: selectedSite,
                                            isExpanded: true,
                                            hint: const Text(
                                              'All',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                            items: [
                                              const DropdownMenuItem<
                                                SiteAutocompleteInfo?
                                              >(
                                                value: null,
                                                child: Text(
                                                  'All',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              ...siteList.map((site) {
                                                final addressParts =
                                                    [
                                                          site.addressLine1,
                                                          site.addressLine2,
                                                          site.city,
                                                          site.state,
                                                          site.pincode,
                                                        ]
                                                        .where(
                                                          (p) =>
                                                              p != null &&
                                                              p
                                                                  .toString()
                                                                  .trim()
                                                                  .isNotEmpty,
                                                        )
                                                        .join(', ');
                                                final displayLabel =
                                                    site.siteName +
                                                    (addressParts.isNotEmpty
                                                        ? ' - $addressParts'
                                                        : '');
                                                return DropdownMenuItem<
                                                  SiteAutocompleteInfo?
                                                >(
                                                  value: site,
                                                  child: Text(
                                                    displayLabel,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: isDownloading
                                                ? null
                                                : (value) {
                                                    dialogSetState(() {
                                                      selectedSite = value;
                                                      selectedTank = null;
                                                    });
                                                    fetchTanks(value?.siteId);
                                                  },
                                          ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tank Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tank Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            isLoadingTanks
                                ? const SizedBox(
                                    height: 38,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    height: 38,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child:
                                          DropdownButton<Map<String, dynamic>?>(
                                            value: selectedTank,
                                            isExpanded: true,
                                            hint: const Text(
                                              'All',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                            items: [
                                              const DropdownMenuItem<
                                                Map<String, dynamic>?
                                              >(
                                                value: null,
                                                child: Text(
                                                  'All',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              ...tankList.map((tank) {
                                                final name =
                                                    tank['tank_number']
                                                        ?.toString() ??
                                                    'N/A';
                                                return DropdownMenuItem<
                                                  Map<String, dynamic>?
                                                >(
                                                  value: tank,
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                            onChanged: isDownloading
                                                ? null
                                                : (value) {
                                                    dialogSetState(() {
                                                      selectedTank = value;
                                                    });
                                                  },
                                          ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isDownloading
                            ? null
                            : () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: (errorMessage.isNotEmpty || isDownloading)
                            ? null
                            : () async {
                                final startDateTime = DateTime(
                                  startDate.year,
                                  startDate.month,
                                  startDate.day,
                                  startTime.hour,
                                  startTime.minute,
                                );
                                final endDateTime = DateTime(
                                  endDate.year,
                                  endDate.month,
                                  endDate.day,
                                  endTime.hour,
                                  endTime.minute,
                                );

                                if (startDateTime.isAfter(endDateTime)) {
                                  dialogSetState(() {
                                    errorMessage =
                                        'Start date must be before end date';
                                  });
                                  return;
                                }

                                dialogSetState(() {
                                  isDownloading = true;
                                  errorMessage = '';
                                });
                                try {
                                  final repository = ref.read(
                                    notificationRepositoryProvider,
                                  );
                                  final startStr = _formatDateTimeForBackend(
                                    startDateTime,
                                  );
                                  final endStr = _formatDateTimeForBackend(
                                    endDateTime,
                                  );

                                  final addressParts = selectedSite == null
                                      ? null
                                      : [
                                              selectedSite!.addressLine1,
                                              selectedSite!.addressLine2,
                                              selectedSite!.city,
                                              selectedSite!.state,
                                              selectedSite!.pincode,
                                            ]
                                            .where(
                                              (p) =>
                                                  p != null &&
                                                  p
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty,
                                            )
                                            .join(', ');

                                  final fileBytes = await repository
                                      .downloadNotificationsExport(
                                        format: type,
                                        startDate: startStr,
                                        endDate: endStr,
                                        plantId: selectedSite?.siteId,
                                        tankId: selectedTank != null
                                            ? (selectedTank!['tank_id'] as int?)
                                            : null,
                                        plantName:
                                            selectedSite?.siteName ?? 'All',
                                        tankName: selectedTank != null
                                            ? selectedTank!['tank_number']
                                                      ?.toString() ??
                                                  'All'
                                            : 'All',
                                        plantAddress: addressParts,
                                      );

                                  if (fileBytes.isEmpty) {
                                    dialogSetState(() {
                                      isDownloading = false;
                                      errorMessage =
                                          'No records found for the selected date range.';
                                    });
                                    return;
                                  }

                                  await FileSaver.instance.saveFile(
                                    name: 'events_report',
                                    bytes: Uint8List.fromList(fileBytes),
                                    ext: type == 'excel' ? 'xlsx' : 'pdf',
                                    mimeType: type == 'excel'
                                        ? MimeType.microsoftExcel
                                        : MimeType.pdf,
                                  );

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                } catch (e) {
                                  dialogSetState(() {
                                    isDownloading = false;
                                    errorMessage = 'Download failed: $e';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141E7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Download ${type == 'excel' ? 'Excel' : 'PDF'}',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
