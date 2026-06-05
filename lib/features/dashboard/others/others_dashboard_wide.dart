import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme/app_theme.dart';
import '../../tank/presentation/view/tank_details_view.dart';
import '../data/models/tank_data_model.dart';
import '../presentation/widgets/build_loading_view.dart';
import '../presentation/widgets/dashboard_list_view.dart';
import '../presentation/widgets/dashboard_map_view.dart';
import '../presentation/widgets/search_and_filters.dart';
import '../presentation/widgets/statistics_cards.dart';
import '../presentation/widgets/view_toggle.dart';
import '../provider/dashboard_controller.dart';
import '../provider/dashboard_provider.dart';

import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;

class OthersDashboardWide extends ConsumerStatefulWidget {
  const OthersDashboardWide({super.key});

  @override
  ConsumerState<OthersDashboardWide> createState() =>
      _OthersDashboardWideState();
}

class _OthersDashboardWideState extends ConsumerState<OthersDashboardWide> {

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All Status';
  String _selectedRegion = 'All Regions';
  String _searchQuery = '';
  bool _isListView = true;

  @override
  Widget build(BuildContext context) {

    /// MQTT + realtime init
    ref.watch(dashboardControllerProvider);
    final tanksAsync = ref.watch(tankDataProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);
    final statistics = ref.watch(tankStatisticsProvider);

    return Container(
      color: Colors.white.withValues(alpha: 0.2),

      child: tanksAsync.when(
        loading: () => buildLoadingView(),
        error: (error, _) => Center(
          child: Text(error.toString()),
        ),

        data: (tanks) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                StatisticsCards(statistics: statistics),
                const SizedBox(height: 30),
                SearchAndFilters(onSearchChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },

                  onRegionChanged: (val) {
                    setState(() {
                      _selectedRegion = val;
                    });
                  },

                  onStatusChanged: (val) {
                    setState(() {
                      _selectedStatus = val;
                    });
                  },

                  onClearFilters: () {
                    setState(() {
                      _selectedRegion = 'All Regions';
                      _selectedStatus = 'All Status';
                      _searchQuery = '';
                    });
                    _searchController.clear();
                  },

                  selectedRegion: _selectedRegion,

                  selectedStatus: _selectedStatus,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ViewToggle(
                      currentView: _isListView ? ViewType.list : ViewType.map,
                      onViewChanged: (val) {
                        setState(() {
                          _isListView = val == ViewType.list;
                        });
                      },
                    ),
                    Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Download Report',
                      onSelected: (value) async {
                        final tanks = ref.read(tankDataProvider).value ?? [];

                        if (value == 'excel') {
                          await exportToExcel(tanks);
                        }

                        if (value == 'pdf') {
                          await exportToPdf(tanks);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart_outlined, color: primary),
                              SizedBox(width: 10),
                              Text('Download Excel'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf_outlined, color: primary),
                              SizedBox(width: 10),
                              Text('Download PDF'),
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
                            Icon(Icons.download, size: 18, color: primary),
                            SizedBox(width: 8),
                            Text('Download', style: TextStyle(color: primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isListView ? DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  searchQuery: _searchQuery,
                  onTankTap: _callDetailsPage,
                ) : DashboardMapView(tanksData: tanks),
              ],
            ),
          );
        },
      ),
    );
  }

  void _callDetailsPage(TankDataModel tank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TankDetailsView(tankId: tank.id, tank: tank),
      ),
    );
  }

  Future<void> exportToExcel(
      List<TankDataModel> tanks,
      ) async {

    final workbook = xls.Workbook();

    final sheet = workbook.worksheets[0];

    /// Header
    sheet.getRangeByName('A1').setText('Tank Name');
    sheet.getRangeByName('B1').setText('Site');
    sheet.getRangeByName('C1').setText('Level');
    sheet.getRangeByName('D1').setText('Pressure');
    sheet.getRangeByName('E1').setText('Battery');
    sheet.getRangeByName('F1').setText('Solar');
    sheet.getRangeByName('G1').setText('Status');

    /// Data
    for (int i = 0; i < tanks.length; i++) {
      final row = i + 2;
      final tank = tanks[i];

      sheet.getRangeByName('A$row').setText(tank.tankName);
      sheet.getRangeByName('B$row').setText(tank.siteName);
      sheet.getRangeByName('C$row').setNumber(tank.level);
      sheet.getRangeByName('D$row').setNumber(tank.pressure);
      sheet.getRangeByName('E$row').setNumber(tank.batteryV);
      sheet.getRangeByName('F$row').setNumber(tank.solarV);
      sheet.getRangeByName('G$row').setText(tank.status);
    }

    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);
    sheet.autoFitColumn(7);

    final List<int> bytes = workbook.saveAsStream();

    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: 'tank_report',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> exportToPdf(
      List<TankDataModel> tanks,
      ) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [

          pw.Text(
            'Tank Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              'Tank',
              'Level',
              'Pressure',
              'Battery',
              'Solar',
              'Status',
            ],
            data: tanks.map((tank) {
              return [
                tank.tankName,
                tank.level.toString(),
                tank.pressure.toString(),
                tank.batteryV.toString(),
                tank.solarV.toString(),
                tank.status,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await FileSaver.instance.saveFile(
      name: 'tank_report',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

}