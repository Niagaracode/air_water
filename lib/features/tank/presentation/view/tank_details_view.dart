import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_details_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_events_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_map_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_readings_tab.dart';
import 'package:air_water/features/tank/presentation/view/threshold_side_sheet.dart';
import 'package:data_table_2/data_table_2.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_config.dart';
import '../../../../core/helpers/date_formatter.dart';
import '../../../../shared/utils/app_text_styles.dart';
import '../../../dashboard/data/models/tank_data_model.dart';
import '../../../dashboard/widgets/tank_level_widget.dart';
import '../../data/model/tank_channel_model.dart';
import '../../data/model/tank_reading_model.dart';
import '../controller/tank_channel_provider.dart';
import '../controller/tank_provider.dart';
import '../controller/tank_readings_provider.dart';


import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdfLib;


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
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: widget.isNarrow ? SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          child: Column(
            children: [
              Column(
                children: [
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
                                        child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
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
                          SizedBox(height: 12),
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
                                      Text(widget.tank.addressLine_1, style: AppTextStyles.body()),
                                      Text(widget.tank.addressLine_2, style: AppTextStyles.body()),
                                      Text(widget.tank.addressLine_3, style: AppTextStyles.body()),
                                      Text(widget.tank.city, style: AppTextStyles.body()),
                                    ],
                                  ),
                                ),
                              ),
                              TankLevelWidget(
                                level: widget.tank.level.toDouble(),
                                svgAsset: AppConfig.current.tankImgPath,
                                gasType: widget.tank.gasType,
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  )
                ],
              ),

              SizedBox(height: 8),
              _buildTabBar(),
              SizedBox(
                height: 350,
                child: TabBarView(
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
              SizedBox(height: 8),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DATA CHANNELS',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Spacer(),
                        TextButton.icon(
                          onPressed: () {

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
                                    channels: channelState.channels,
                                    onSave: (Map<String, dynamic> payload) async {
                                      // payload contains the complete JSON structure with tankId
                                      print('Complete payload to save: $payload');

                                      try {
                                        // Call the repository to update
                                        final tankRepository = ref.read(tankRepositoryProvider);
                                        await tankRepository.updateTankChannelEvent(widget.tankId, payload);

                                        // Show success message
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Thresholds updated successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                      } catch (e) {
                                        // Show error message
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

                                final tween = Tween(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                );

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            );
                          },

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
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 5, right: 16),
                    child: Container(
                      height: _calculateTableHeight(channelState.channels),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: channelState.isLoading ? Center(
                        child: CircularProgressIndicator(),
                      ) : DataTable2(
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        minWidth: 700,
                        headingRowHeight: 35,
                        dataRowHeight: 35,
                        headingRowDecoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        columns: const [

                          DataColumn2(
                            label: Text('CHANNEL'),
                            fixedWidth: 150,
                          ),

                          DataColumn2(
                            label: Text('LAST READING'),
                            fixedWidth: 140,
                          ),
                          DataColumn2(
                            label: Text('READING TIME'),
                            fixedWidth: 170,
                          ),
                          DataColumn2(
                            label: Text('THRESHOLDS'),
                            size: ColumnSize.M,
                          ),
                        ],
                        rows: channelState.channels
                            .where((item) => item.channelEnable).map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getChannelIcon(item.name),
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(item.name),
                                ],
                              )),
                              DataCell(
                                Text('${item.value.toString()} ${getChannelUnit(item.name)}'),
                              ),
                              DataCell(
                                Text(
                                  formatDateTime(item.readingTime),
                                ),
                              ),
                              DataCell(
                                Text(
                                  buildThresholdText(item.threshold),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ) :
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        child: Column(
          children: [
            Column(
              children: [
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
                                      child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
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
                        SizedBox(height: 12),
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
                                    Text(widget.tank.addressLine_1, style: AppTextStyles.body()),
                                    Text(widget.tank.addressLine_2, style: AppTextStyles.body()),
                                    Text(widget.tank.addressLine_3, style: AppTextStyles.body()),
                                    Text(widget.tank.city, style: AppTextStyles.body()),
                                  ],
                                ),
                              ),
                            ),
                            TankLevelWidget(
                              level: widget.tank.level.toDouble(),
                              svgAsset: AppConfig.current.tankImgPath,
                              gasType: widget.tank.gasType,
                            ),
                          ],
                        )
                      ],
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DATA CHANNELS',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Spacer(),
                                TextButton.icon(
                                  onPressed: () {

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
                                            channels: channelState.channels,
                                            onSave: (Map<String, dynamic> payload) async {
                                              // payload contains the complete JSON structure with tankId
                                              print('Complete payload to save: $payload');

                                              try {
                                                // Call the repository to update
                                                final tankRepository = ref.read(tankRepositoryProvider);
                                                await tankRepository.updateTankChannelEvent(widget.tankId, payload);

                                                // Show success message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Thresholds updated successfully'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );

                                              } catch (e) {
                                                // Show error message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error updating thresholds: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }

                                            },
                                            isNarrow: widget.isNarrow,
                                          ),
                                        );
                                      },

                                      transitionBuilder: (context, animation, secondaryAnimation, child) {

                                        final tween = Tween(
                                          begin: const Offset(1, 0),
                                          end: Offset.zero,
                                        );

                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    );
                                  },

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
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 5),
                            child: Container(
                              height: _calculateTableHeight(channelState.channels),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x05000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: channelState.isLoading ? Center(
                                child: CircularProgressIndicator(),
                              ) : DataTable2(
                                columnSpacing: 16,
                                horizontalMargin: 12,
                                minWidth: 700,
                                headingRowHeight: 35,
                                dataRowHeight: 35,
                                headingRowDecoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                columns: const [

                                  DataColumn2(
                                    label: Text('CHANNEL'),
                                    fixedWidth: 150,
                                  ),

                                  DataColumn2(
                                    label: Text('LAST READING'),
                                    fixedWidth: 140,
                                  ),
                                  DataColumn2(
                                    label: Text('READING TIME'),
                                    fixedWidth: 170,
                                  ),
                                  DataColumn2(
                                    label: Text('THRESHOLDS'),
                                    size: ColumnSize.M,
                                  ),
                                ],
                                rows: channelState.channels
                                    .where((item) => item.channelEnable).map((item) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            getChannelIcon(item.name),
                                            color: Colors.black87,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(item.name),
                                        ],
                                      )),
                                      DataCell(
                                        Text('${item.value.toString()} ${getChannelUnit(item.name)}'),
                                      ),
                                      DataCell(
                                        Text(
                                          formatDateTime(item.readingTime),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          buildThresholdText(item.threshold),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                )
              ],
            ),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
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
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {

    if(widget.isNarrow){
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Tabs
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
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Graph'),
                    Tab(text: 'Events'),
                    Tab(text: 'Readings'),
                    Tab(text: 'Map'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Segmented Button (Date Range)
              SizedBox(
                height: widget.isNarrow? 42:32,
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
                    ButtonSegment(
                      value: '1D',
                      label: Text('1D'),
                    ),
                    ButtonSegment(
                      value: '2D',
                      label: Text('2D'),
                    ),
                    ButtonSegment(
                      value: '4D',
                      label: Text('4D'),
                    ),
                    ButtonSegment(
                      value: '1W',
                      label: Text('1W'),
                    ),
                    ButtonSegment(
                      value: '2W',
                      label: Text('2W'),
                    ),
                    ButtonSegment(
                      value: '3W',
                      label: Text('3W'),
                    ),
                    ButtonSegment(
                      value: '1M',
                      label: Text('1M'),
                    ),
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
                height: 32,
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
                    foregroundColor: isCustomSelected
                        ? Colors.white
                        : primary,
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
              PopupMenuButton<String>(
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
                    await exportTankReadingsExcel(readings, reportTitle);
                  }
                  if (value == 'pdf') {
                    await exportTankReadingsPdf(readings);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.download,
                        size: 16,
                        color: primary,
                      ),
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
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
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
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Graph'),
              Tab(text: 'Events'),
              Tab(text: 'Readings'),
              Tab(text: 'Map'),
            ],
          ),
          Spacer(),
          // Segmented Button (Date Range)
          SizedBox(
            height: 32,
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
                ButtonSegment(
                  value: '1D',
                  label: Text('1D'),
                ),
                ButtonSegment(
                  value: '2D',
                  label: Text('2D'),
                ),
                ButtonSegment(
                  value: '4D',
                  label: Text('4D'),
                ),
                ButtonSegment(
                  value: '1W',
                  label: Text('1W'),
                ),
                ButtonSegment(
                  value: '2W',
                  label: Text('2W'),
                ),
                ButtonSegment(
                  value: '3W',
                  label: Text('3W'),
                ),
                ButtonSegment(
                  value: '1M',
                  label: Text('1M'),
                ),
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
            height: 32,
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
                foregroundColor: isCustomSelected
                    ? Colors.white
                    : primary,
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
          PopupMenuButton<String>(
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
                await exportTankReadingsExcel(readings, reportTitle);
              }
              if (value == 'pdf') {
                await exportTankReadingsPdf(readings);
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.download,
                    size: 16,
                    color: primary,
                  ),
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
          ),
        ],
      ),
    );
  }

  /// Custom Date Range Popup Dialog
  void _showCustomDateRangePopup() {
    // Initialize with current date range
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 23, minute: 59);

    String errorMessage = '';

    // Validation function
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
                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: primary,
                      ),
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

                  // Date Range Selection - Row 1
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

                  // Date Range Selection - Row 2
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

                  // Date Range Summary
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: primary,
                        ),
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

                          debugPrint('STATE UPDATED');
                          debugPrint('customStartDate=$customStartDate');
                          debugPrint('customEndDate=$customEndDate');

                          // Close the dialog
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

  double _calculateTableHeight(List<dynamic> channels) {
    final enabledChannelsCount = channels.where((item) => item.channelEnable).length;
    if (enabledChannelsCount == 0) {
      return 100;
    }

    final headingRowHeight = 35.0;
    final dataRowHeight = 35.0;
    final bottomPadding = 8.0;

    return headingRowHeight + (enabledChannelsCount * dataRowHeight) + bottomPadding;
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
      items.add(
        'F: ${threshold.full!.comparator} ${threshold.full!.value}',
      );
    }

    if (threshold.reorder != null) {
      items.add(
        'R: ${threshold.reorder!.comparator} ${threshold.reorder!.value}',
      );
    }

    if (threshold.critical != null) {
      items.add(
        'C: ${threshold.critical!.comparator} ${threshold.critical!.value}',
      );
    }

    if (threshold.low != null) {
      items.add(
        'L: ${threshold.low!.comparator} ${threshold.low!.value}',
      );
    }

    return items.join('    ');
  }

  String formatDateTime(String dateTime) {
    try {
      final parsedDate =
      DateFormat('dd/MM/yyyy HH:mm:ss')
          .parse(dateTime);

      return DateFormat(
        'dd/MM/yyyy hh:mm a',
      ).format(parsedDate);

    } catch (e) {
      return dateTime;
    }
  }

  Future<void> exportTankReadingsExcel(
      List<TankReadingModel> readings,
      String reportTitle,
      ) async {

    if (!mounted) return;

    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];

    sheet.name = 'Tank Report';

    // =========================
    // TITLE
    // =========================

    final titleRange = sheet.getRangeByName('A1:G2');
    titleRange.merge();

    titleRange.setText('TANK READINGS REPORT');

    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontSize = 20;
    titleRange.cellStyle.fontColor = '#FFFFFF';
    titleRange.cellStyle.backColor = '#1F4E78';
    titleRange.cellStyle.hAlign = xls.HAlignType.center;
    titleRange.cellStyle.vAlign = xls.VAlignType.center;

    // =========================
    // REPORT INFO
    // =========================


    sheet.getRangeByName('A4').setText('Site Name');
    sheet.getRangeByName('B4').setText(widget.tank.siteName);

    sheet.getRangeByName('A5').setText('Product Name');
    sheet.getRangeByName('B5').setText('${widget.tank.tankName}(${widget.tank.gasType})');

    sheet.getRangeByName('A6').setText('Device ID');
    sheet.getRangeByName('B6').setText(widget.tank.deviceId);



    sheet.getRangeByName('D5').setText('Generated On');
    sheet.getRangeByName('E5').setText(
      DateFormat('dd-MM-yyyy hh:mm a').format(
        DateTime.now(),
      ),
    );

    sheet.getRangeByName('D6').setText('Total Readings');
    sheet.getRangeByName('E6').setText(
      readings.length.toString(),
    );

    for (final cell in [
      'A4',
      'A5',
      'A6',
      'D4',
      'D5',
      'D6'
    ]) {
      sheet.getRangeByName(cell).cellStyle.bold = true;
    }

    // =========================
    // TABLE HEADER
    // =========================

    const tableHeaderRow = 8;

    sheet.getRangeByName('A$tableHeaderRow')
        .setText('Date Time');

    sheet.getRangeByName('B$tableHeaderRow')
        .setText('Time');

    sheet.getRangeByName('C$tableHeaderRow')
        .setText('Level (%)');

    sheet.getRangeByName('D$tableHeaderRow')
        .setText('Pressure (Bar)');

    sheet.getRangeByName('E$tableHeaderRow')
        .setText('Battery (V)');

    sheet.getRangeByName('F$tableHeaderRow')
        .setText('Solar (V)');

    sheet.getRangeByName('G$tableHeaderRow')
        .setText('Volume (L)');

    final headerRange = sheet.getRangeByName('A8:G8');

    headerRange.cellStyle.bold = true;
    headerRange.cellStyle.fontColor = '#FFFFFF';
    headerRange.cellStyle.backColor = '#4472C4';
    headerRange.cellStyle.hAlign =
        xls.HAlignType.center;

    // =========================
    // DATA
    // =========================

    for (int i = 0; i < readings.length; i++) {

      final row = i + 9;

      final item = readings[i];

      sheet.getRangeByName('A$row').setText(
        DateFormatter.formatDateTime(
          item.createdAt,
        ),
      );

      sheet.getRangeByName('B$row')
          .setText(item.time);

      sheet.getRangeByName('C$row')
          .setText(item.level.toString());

      sheet.getRangeByName('D$row')
          .setText(item.pressure.toString());

      sheet.getRangeByName('E$row')
          .setText(item.battery.toString());

      sheet.getRangeByName('F$row')
          .setText(item.solar.toString());

      sheet.getRangeByName('G$row')
          .setText(item.volume.toString());

      // Alternate row colors
      if (i.isEven) {
        sheet.getRangeByName(
            'A$row:G$row')
            .cellStyle
            .backColor = '#F8F9FA';
      }
    }

    // =========================
    // BORDERS
    // =========================

    final lastRow = readings.length + 8;

    final tableRange =
    sheet.getRangeByName('A8:G$lastRow');


    tableRange.cellStyle.borders.all
        .lineStyle = xls.LineStyle.thin;

    // =========================
    // FREEZE HEADER
    // =========================

    sheet.getRangeByName('A12').freezePanes();

    // =========================
    // AUTO FIT
    // =========================

    for (int i = 1; i <= 7; i++) {
      sheet.autoFitColumn(i);
    }

    // =========================
    // SAVE
    // =========================

    final bytes =
    workbook.saveAsStream();

    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: reportTitle,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> exportTankReadingsPdf(
      List<TankReadingModel> readings,
      ) async {

    final pdf = pw.Document();

    final svgLogo = await rootBundle.loadString(
      'assets/svg/company_logo.svg',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdfLib.PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          // Header Section
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: pdfLib.PdfColors.blue,
                  width: 2,
                ),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  decoration: const pw.BoxDecoration(), // Removes default line
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Tank Readings Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SvgImage(
                        svg: svgLogo,
                        fit: pw.BoxFit.contain,
                        height: 25,
                      ),
                    ],
                  ),
                ),

                // Tank Details in a grid layout
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Site Name', widget.tank.siteName),
                          _buildDetailRow('Tank Id & Gas', '${widget.tank.tankName}(${widget.tank.gasType})'),
                          _buildDetailRow('Device SNo', widget.tank.deviceId),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('City', widget.tank.city),
                          _buildDetailRow('Generated On',
                              DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now())
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Data Table
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: pdfLib.PdfColors.grey300,
                width: 1,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Table.fromTextArray(
              headers: [
                'Date Time',
                'Level',
                'Pressure',
                'Battery',
                'Solar',
                'Volume',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: pdfLib.PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(
                color: pdfLib.PdfColors.blue,
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(4),
                  topRight: pw.Radius.circular(4),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(
                fontSize: 9,
                color: pdfLib.PdfColors.black,
              ),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: pdfLib.PdfColors.grey200,
                    width: 0.5,
                  ),
                ),
              ),
              data: readings.map((item) {
                return [
                  DateFormatter.formatDateTime(item.createdAt),
                  '${item.level.toString()}%',
                  '${item.pressure.toString()} Bar',
                  '${item.battery.toString()} V',
                  '${item.solar.toString()} V',
                  '${item.volume.toString()} L',
                ];
              }).toList(),
            ),
          ),

          pw.SizedBox(height: 20),

          // Footer (without page number)
          pw.Container(
            alignment: pw.Alignment.center,
            padding: pw.EdgeInsets.only(top: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: pdfLib.PdfColors.grey200,
                  width: 1,
                ),
              ),
            ),
            child: pw.Text(
              'Generated by AirWater System',
              style: pw.TextStyle(
                fontSize: 9,
                color: pdfLib.PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await FileSaver.instance.saveFile(
      name: '${widget.tank.tankName}_readings_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: pdfLib.PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(
              fontSize: 11,
              color: pdfLib.PdfColors.grey500,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: pdfLib.PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

}