import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_details_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_events_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_map_tab.dart';
import 'package:air_water/features/tank/presentation/view/tabs/tank_readings_tab.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_details_header.dart';
import '../../../dashboard/data/models/tank_data_model.dart';
import '../../data/model/tank_reading_model.dart';
import '../controller/tank_readings_provider.dart';


import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;


class TankDetailsView extends ConsumerStatefulWidget {
  final int tankId;
  final TankDataModel tank;

  const TankDetailsView({
    super.key,
    required this.tankId,
    required this.tank,
  });

  @override
  ConsumerState<TankDetailsView> createState() => _TankDetailsViewState();
}

class _TankDetailsViewState extends ConsumerState<TankDetailsView>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String selectedSegment = '1D';


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

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: Row(
                children: [
                  /// HEADER
                  Expanded(
                    child: AppDetailsHeader(
                      title:
                      '${widget.tank.tankName} - Tank Nr: ${widget.tank.deviceId}',
                      subtitle: '${widget.tank.siteName} - City : ${widget.tank.city} - State : ${widget.tank.region}',
                      breadcrumbs: [],
                      onBack: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  /// DOWNLOAD BUTTON
                  PopupMenuButton<String>(
                    tooltip: 'Download Report',
                    onSelected: (value) async {
                      final readings = ref.read(
                        tankReadingsProvider(
                          TankReadingParams(
                            tankId: widget.tankId,
                            day: selectedSegment,
                          ),
                        ),
                      ).readings;

                      if (readings.isEmpty) return;

                      if (value == 'excel') {
                        await exportTankReadingsExcel(readings);
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
                            Icon(
                              Icons.table_chart_outlined,
                              color: primary,
                            ),

                            const SizedBox(width: 10),

                            const Text('Download Excel'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf_outlined,
                              color: primary,
                            ),

                            const SizedBox(width: 10),

                            const Text('Download PDF'),
                          ],
                        ),
                      ),
                    ],

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
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
                            size: 18,
                            color: primary,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'Download',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildTabBar(),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  TankDetailsTab(tankId: widget.tankId, day: selectedSegment),
                  TankEventsTab(tankId: widget.tankId, day: selectedSegment),
                  TankReadingsTab(tankId: widget.tankId, day: selectedSegment),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,

              indicatorSize: TabBarIndicatorSize.label,

              labelColor: const Color(0xFF141E7A),
              unselectedLabelColor: Colors.grey,

              indicatorColor: const Color(0xFF141E7A),
              indicatorWeight: 2,

              dividerColor: Colors.transparent,

              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),

              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Events'),
                Tab(text: 'Readings'),
                Tab(text: 'Map'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          /// SEGMENT
          SizedBox(
            height: 34,
            child: SegmentedButton<String>(
              style: ButtonStyle(
                side: WidgetStateProperty.resolveWith((states) {
                    return  BorderSide(
                      color: Colors.grey.withValues(alpha: 0.6),
                      width: 1,
                    );
                  },
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return primary.withValues(alpha: 0.7);
                    }
                    return Colors.white;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return primary;
                  },
                ),
                visualDensity: VisualDensity.compact,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8),
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
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> exportTankReadingsExcel(List<TankReadingModel> readings) async {

    if (!mounted) return;

    final workbook = xls.Workbook();

    final sheet = workbook.worksheets[0];

    /// HEADER
    sheet.getRangeByName('A1').setText('TNP');
    sheet.getRangeByName('B1').setText('Time');
    sheet.getRangeByName('C1').setText('Level');
    sheet.getRangeByName('D1').setText('Pressure');
    sheet.getRangeByName('E1').setText('Battery');
    sheet.getRangeByName('F1').setText('Solar');
    sheet.getRangeByName('G1').setText('Volume');


    /// DATA
    for (int i = 0; i < readings.length; i++) {

      final row = i + 2;

      final item = readings[i];

      sheet.getRangeByName('A$row').setText(
        DateFormat('dd-MM-yyyy HH:mm:ss').format(item.createdAt),
      );
      sheet.getRangeByName('B$row').setText(item.time);
      sheet.getRangeByName('C$row').setNumber(item.level);
      sheet.getRangeByName('D$row').setNumber(item.pressure);
      sheet.getRangeByName('E$row').setNumber(item.battery);
      sheet.getRangeByName('F$row').setNumber(item.solar);
      sheet.getRangeByName('G$row').setNumber(item.volume);

    }

    for (int i = 1; i <= 7; i++) {
      sheet.autoFitColumn(i);
    }

    final List<int> bytes = workbook.saveAsStream();

    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: 'tank_readings_report',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> exportTankReadingsPdf(
      List<TankReadingModel> readings,
      ) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [

          pw.Text(
            'Tank Readings Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(

            headers: [
              'Date Time',
              'Time',
              'Level',
              'Pressure',
              'Battery',
              'Solar',
              'Volume',
            ],

            data: readings.map((item) {

              return [

                DateFormat(
                  'dd-MM-yyyy HH:mm:ss',
                ).format(item.createdAt),

                item.time,

                item.level.toString(),

                item.pressure.toString(),

                item.battery.toString(),

                item.solar.toString(),

                item.volume.toString(),
              ];

            }).toList(),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await FileSaver.instance.saveFile(
      name: 'tank_readings_report',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

}