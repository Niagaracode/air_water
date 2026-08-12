import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_details_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_events_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_map_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_readings_tab.dart';
import 'package:air_water/features/tank/presentation/view/threshold_side_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_config.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../shared/utils/app_text_styles.dart';
import '../../../dashboard/data/models/tank_data_model.dart';
import '../../../dashboard/utils/tank_readings_report_exporter.dart';
import '../../../dashboard/widgets/tank_level_widget.dart';
import '../../data/model/tank_channel_model.dart';
import '../controller/tank_channel_provider.dart';
import '../controller/tank_provider.dart';
import '../controller/tank_readings_provider.dart';
import '../widgets/data_channel_card.dart';

class TankDetailsView extends ConsumerStatefulWidget {
  final int tankId;
  final TankDataModel tank;
  final bool isNarrow;

  const TankDetailsView({
    super.key,
    required this.tankId,
    required this.tank,
    required this.isNarrow,
  });

  @override
  ConsumerState<TankDetailsView> createState() => _TankDetailsViewState();
}

class _TankDetailsViewState extends ConsumerState<TankDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedSegment = '1D';

  DateTime? customStartDate;
  DateTime? customEndDate;

  bool get isCustomSelected =>
      customStartDate != null &&
          customEndDate != null &&
          selectedSegment.isEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelState = ref.watch(tankChannelProvider(widget.tankId));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Header with tank info and data channels
            SliverToBoxAdapter(
              child: widget.isNarrow
                  ? _buildNarrowHeader(channelState)
                  : _buildWideHeader(channelState),
            ),
            // Tab Bar
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            TankDetailsTab(
              tankId: widget.tankId,
              day: selectedSegment.isEmpty ? null : selectedSegment,
              startDate: customStartDate,
              endDate: customEndDate,
            ),
            TankEventsTab(
              tankId: widget.tankId,
              day: selectedSegment.isEmpty ? null : selectedSegment,
            ),
            TankReadingsTab(
              tankId: widget.tankId,
              day: selectedSegment.isEmpty ? null : selectedSegment,
              startDate: customStartDate,
              endDate: customEndDate,
            ),
            TankMapTab(),
          ],
        ),
      ),
    );
  }

  // ==================== NARROW HEADER ====================
  Widget _buildNarrowHeader(TankChannelState channelState) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        children: [
          // Tank Info
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 420,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 35,
                          child: Tooltip(
                            message: 'Back',
                            child: InkWell(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.tank.siteName,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 260,
                        height: 200,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.tank.addressLine_1,
                                  style: AppTextStyles.body()),
                              Text(widget.tank.addressLine_2,
                                  style: AppTextStyles.body()),
                              Text(widget.tank.addressLine_3,
                                  style: AppTextStyles.body()),
                              Text(widget.tank.city,
                                  style: AppTextStyles.body()),
                            ],
                          ),
                        ),
                      ),
                      TankLevelWidget(
                        level: widget.tank.level.toDouble(),
                        svgAsset: AppConfig.current.tankImgPath,
                        gasType: widget.tank.gasType,
                        minLevel: widget.tank.minLevel,
                        maxLevel: widget.tank.maxLevel,
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Data Channels Section - Pass both parameters
          _buildDataChannelsSection(channelState),
        ],
      ),
    );
  }

// ==================== WIDE HEADER ====================
  Widget _buildWideHeader(TankChannelState channelState) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Tank Info
              Column(
                children: [
                  SizedBox(
                    width: 420,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 35,
                          child: Tooltip(
                            message: 'Back',
                            child: InkWell(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.tank.siteName,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 420,
                    height: 150,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 70),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.tank.addressLine_1,
                              style: AppTextStyles.body()),
                          Text(widget.tank.addressLine_2,
                              style: AppTextStyles.body()),
                          Text(widget.tank.addressLine_3,
                              style: AppTextStyles.body()),
                          Text(widget.tank.city, style: AppTextStyles.body()),
                        ],
                      ),
                    ),
                  ),
                  TankLevelWidget(
                    level: widget.tank.level.toDouble(),
                    svgAsset: AppConfig.current.tankImgPath,
                    gasType: widget.tank.gasType,
                    minLevel: widget.tank.minLevel,
                    maxLevel: widget.tank.maxLevel,
                  ),
                ],
              ),
              // Right Column - Data Channels - Pass both parameters
              Expanded(
                child: _buildDataChannelsSection(channelState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== DATA CHANNELS SECTION ====================
  Widget _buildDataChannelsSection(
      TankChannelState channelState,
      ) {
    final List<TankChannelModel> channels = channelState.channels;
    final bool isLoading = channelState.isLoading;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DATA CHANNELS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showThresholdSideSheet(channels),
                icon: Icon(
                  Icons.view_headline_sharp,
                  color: primary,
                  size: 18,
                ),
                label: Text(
                  'View Event Details',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showViewSettingsDialog(),
                icon: Icon(
                  Icons.settings,
                  color: primary,
                  size: 18,
                ),
                label: Text(
                  'View Settings',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: isLoading
              ? const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          )
              : _buildDataChannelCards(
            context,
            channels,
          ),
        ),
      ],
    );
  }

  // ==================== DATA CHANNEL CARDS ====================
  Widget _buildDataChannelCards(
      BuildContext context,
      List<TankChannelModel> channels,
      ) {
    final enabledChannels = channels
        .where((item) => item.channelEnable)
        .toList();

    if (enabledChannels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text(
            'No enabled channels',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;
        if (width >= 900) {
          columns = 4;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 12.0;
        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: enabledChannels.map((item) {
            return SizedBox(
              width: cardWidth,
              child: DataChannelCard(
                channelName: item.name,
                value: item.value,
                unit: getChannelUnit(item.name),
                readingTime: DateFormatter.formatDateTime(item.readingTime),
                thresholdText: 'Threshold : ${buildThresholdText(item.threshold)}',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==================== TAB BAR ====================
  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: widget.isNarrow
          ? _buildNarrowTabBar()
          : _buildWideTabBar(),
    );
  }

  Widget _buildWideTabBar() {
    return Row(
      children: [
        // Tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Graph'),
            Tab(text: 'Events'),
            Tab(text: 'Readings'),
            Tab(text: 'Map'),
          ],
        ),
        const Spacer(),
        // Date Range Controls
        _buildDateRangeControls(),
      ],
    );
  }

  Widget _buildNarrowTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.65,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primary,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Graph'),
                Tab(text: 'Events'),
                Tab(text: 'Readings'),
                Tab(text: 'Map'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildDateRangeControls(),
        ],
      ),
    );
  }

  // ==================== DATE RANGE CONTROLS ====================
  Widget _buildDateRangeControls() {
    return Row(
      children: [
        // Segmented Button
        SizedBox(
          height: widget.isNarrow ? 42 : 32,
          child: SegmentedButton<String>(
            style: ButtonStyle(
              side: WidgetStateProperty.resolveWith((states) {
                return BorderSide(
                  color: Colors.grey.withValues(alpha: 0.6),
                  width: 1,
                );
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary.withValues(alpha: 0.7);
                }
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return primary;
              }),
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 6),
              ),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 11),
              ),
            ),
            segments: const [
              ButtonSegment(value: '1D', label: Text('1D')),
              ButtonSegment(value: '2D', label: Text('2D')),
              ButtonSegment(value: '4D', label: Text('4D')),
              ButtonSegment(value: '1W', label: Text('1W')),
              ButtonSegment(value: '2W', label: Text('2W')),
              ButtonSegment(value: '3W', label: Text('3W')),
              ButtonSegment(value: '1M', label: Text('1M')),
            ],
            selected: {selectedSegment},
            onSelectionChanged: (value) {
              setState(() {
                selectedSegment = value.first;
                customStartDate = null;
                customEndDate = null;
              });
            },
          ),
        ),
        const SizedBox(width: 8),

        // Custom Button
        SizedBox(
          height: widget.isNarrow ? 42 : 32,
          child: OutlinedButton(
            onPressed: _showCustomDateRangePopup,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isCustomSelected
                    ? primary
                    : Colors.grey.withValues(alpha: 0.6),
                width: isCustomSelected ? 2 : 1,
              ),
              backgroundColor: isCustomSelected
                  ? primary.withValues(alpha: 0.7)
                  : Colors.white,
              foregroundColor: isCustomSelected ? Colors.white : primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: isCustomSelected ? Colors.white : primary,
                ),
                const SizedBox(width: 3),
                Text(
                  isCustomSelected ? 'Custom ✓' : 'Custom',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isCustomSelected ? Colors.white : primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Download Button
        _buildDownloadButton(),
      ],
    );
  }

  // ==================== DOWNLOAD BUTTON ====================
  Widget _buildDownloadButton() {
    return PopupMenuButton<String>(
      tooltip: 'Download Report',
      onSelected: (value) async {
        final readings = ref.read(
          tankReadingsProvider(
            TankReadingParams(
              tankId: widget.tankId,
              day: isCustomSelected ? null : selectedSegment,
              startDate: customStartDate,
              endDate: customEndDate,
            ),
          ),
        ).readings;

        if (readings.isEmpty) return;

        final reportTitle = _getReportTitle();

        if (value == 'excel') {
          await TankReadingsReportExporter.exportExcel(
            readings: readings,
            tank: widget.tank,
            reportTitle: reportTitle,
          );
        }
        if (value == 'pdf') {
          await TankReadingsReportExporter.exportPdf(
            readings: readings,
            tank: widget.tank,
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, color: primary),
              const SizedBox(width: 10),
              const Text('Download Excel'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: primary),
              const SizedBox(width: 10),
              const Text('Download PDF'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.download, size: 16, color: primary),
            const SizedBox(width: 6),
            Text(
              'Download',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewSettingsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Device Settings',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero);
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ==================== THRESHOLD SIDE SHEET ====================
  void _showThresholdSideSheet(List<TankChannelModel> channels) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Threshold',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: ThresholdSideSheet(
            isNarrow: widget.isNarrow,
            channels: channels,
            onSave: (Map<String, dynamic> payload) async {
              print('Complete payload to save: $payload');
              try {
                final tankRepository = ref.read(tankRepositoryProvider);
                await tankRepository.updateTankChannelEvent(widget.tankId, payload);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thresholds updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the channel data
                ref.invalidate(tankChannelProvider(widget.tankId));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating thresholds: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero);
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // ==================== CUSTOM DATE RANGE POPUP ====================
  void _showCustomDateRangePopup() {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);
    String errorMessage = '';

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

      final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
      if (startDateOnly.isAfter(todayDate)) {
        errorMessage = 'Start date cannot be in the future';
        return false;
      }

      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      if (endDateOnly.isAfter(todayDate)) {
        errorMessage = 'End date cannot be in the future';
        return false;
      }

      if (!startDateTime.isBefore(endDateTime)) {
        errorMessage = 'End date/time must be after start date/time';
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
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        'Custom Date Range',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // From Date & Time
                  Row(
                    children: [
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
                              onTap: () async {
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
                                        DateFormat('dd-MM-yyyy').format(startDate),
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
                              onTap: () async {
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

                  // To Date & Time
                  Row(
                    children: [
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
                              onTap: () async {
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
                                        DateFormat('dd-MM-yyyy').format(endDate),
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
                              onTap: () async {
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

                  // Error Message
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
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

                  // Summary
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected range: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime(
                              startDate.year,
                              startDate.month,
                              startDate.day,
                              startTime.hour,
                              startTime.minute,
                            ))} - ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime(
                              endDate.year,
                              endDate.month,
                              endDate.day,
                              endTime.hour,
                              endTime.minute,
                            ))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
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
                        onPressed: errorMessage.isEmpty && isValidRange()
                            ? () {
                          final selectedStartDate = DateTime(
                            startDate.year,
                            startDate.month,
                            startDate.day,
                            startTime.hour,
                            startTime.minute,
                          );

                          final selectedEndDate = DateTime(
                            endDate.year,
                            endDate.month,
                            endDate.day,
                            endTime.hour,
                            endTime.minute,
                          );

                          setState(() {
                            selectedSegment = '';
                            customStartDate = selectedStartDate;
                            customEndDate = selectedEndDate;
                          });

                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Date range applied: ${DateFormat('MM/dd/yyyy HH:mm').format(selectedStartDate)} - ${DateFormat('MM/dd/yyyy HH:mm').format(selectedEndDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorMessage.isEmpty && isValidRange()
                              ? primary
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Apply'),
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

  // ==================== HELPER METHODS ====================
  String _getReportTitle() {
    final siteName = widget.tank.siteName;
    final tankName = widget.tank.tankName;
    final deviceId = widget.tank.deviceId;
    final dateRange = _getDateRangeLabel();
    return '${siteName}_${tankName}_${deviceId}_$dateRange';
  }

  String _getDateRangeLabel() {
    switch (selectedSegment) {
      case '1D':
        return 'Last 24 Hours';
      case '2D':
        return 'Last 2 Days';
      case '4D':
        return 'Last 4 Days';
      case '1W':
        return 'Last 7 Days';
      case '2W':
        return 'Last 14 Days';
      case '3W':
        return 'Last 21 Days';
      case '1M':
        return 'Last 30 Days';
      default:
        return 'Selected Period';
    }
  }

  IconData getChannelIcon(String name) {
    switch (name.toLowerCase()) {
      case 'level':
        return Icons.gas_meter_outlined;
      case 'pressure':
        return Icons.speed;
      case 'battery voltage':
        return Icons.battery_0_bar_rounded;
      case 'solar voltage':
        return Icons.solar_power;
      default:
        return Icons.sensors;
    }
  }

  String getChannelUnit(String name) {
    switch (name.toLowerCase()) {
      case 'level':
        return '%';
      case 'pressure':
        return 'Bar';
      case 'battery voltage':
        return 'Volts';
      case 'solar voltage':
        return 'Volts';
      default:
        return '';
    }
  }

  String buildThresholdText(ThresholdModel threshold) {
    List<String> items = [];
    if (threshold.full != null) {
      items.add('F: ${threshold.full!.comparator} ${threshold.full!.value}');
    }
    if (threshold.reorder != null) {
      items.add('R: ${threshold.reorder!.comparator} ${threshold.reorder!.value}');
    }
    if (threshold.critical != null) {
      items.add('C: ${threshold.critical!.comparator} ${threshold.critical!.value}');
    }
    if (threshold.low != null) {
      items.add('L: ${threshold.low!.comparator} ${threshold.low!.value}');
    }
    return items.join('    ');
  }
}