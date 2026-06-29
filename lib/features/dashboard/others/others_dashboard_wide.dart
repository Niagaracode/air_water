import 'package:air_water/core/user_config/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdfLib;

import '../../../core/app_theme/app_theme.dart';
import '../../tank/presentation/view/tank_details_view.dart';
import '../data/models/tank_data_model.dart';
import '../provider/dashboard_controller.dart';
import '../provider/dashboard_provider.dart';

import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;

import '../widgets/build_loading_view.dart';
import '../widgets/dashboard_list_view.dart';
import '../widgets/dashboard_map_view.dart';
import '../widgets/search_and_filters.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/view_toggle.dart';

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
  String _selectedProduct = 'All Product'; // ADDED this
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
                SearchAndFilters(
                  onSearchChanged: (val) {
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

                  onProductChanged: (val) { // ADDED this
                    setState(() {
                      _selectedProduct = val;
                    });
                  },

                  onClearFilters: () {
                    setState(() {
                      _selectedRegion = 'All Regions';
                      _selectedStatus = 'All Status';
                      _selectedProduct = 'All Product'; // ADDED this
                      _searchQuery = '';
                    });
                    _searchController.clear();
                  },

                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  selectedProduct: _selectedProduct, // ADDED this
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
                    const Spacer(),
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
                            const SizedBox(width: 8),
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
                  selectedProduct: _selectedProduct, // ADDED this
                  searchQuery: _searchQuery,
                  userRole: UserRole.superAdmin,
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

    /// Header - ADDED Product column
    sheet.getRangeByName('A1').setText('Tank Name');
    sheet.getRangeByName('B1').setText('Site');
    sheet.getRangeByName('C1').setText('Product'); // ADDED this
    sheet.getRangeByName('D1').setText('Level');
    sheet.getRangeByName('E1').setText('Pressure');
    sheet.getRangeByName('F1').setText('Battery');
    sheet.getRangeByName('G1').setText('Solar');
    sheet.getRangeByName('H1').setText('Status');

    /// Data
    for (int i = 0; i < tanks.length; i++) {
      final row = i + 2;
      final tank = tanks[i];

      sheet.getRangeByName('A$row').setText(tank.tankName);
      sheet.getRangeByName('B$row').setText(tank.siteName);
      sheet.getRangeByName('C$row').setText(tank.gasType); // ADDED this
      sheet.getRangeByName('D$row').setNumber(tank.level);
      sheet.getRangeByName('E$row').setNumber(tank.pressure);
      sheet.getRangeByName('F$row').setNumber(tank.batteryV);
      sheet.getRangeByName('G$row').setNumber(tank.solarV);
      sheet.getRangeByName('H$row').setText(tank.status);
    }

    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);
    sheet.autoFitColumn(7);
    sheet.autoFitColumn(8); // ADDED this

    final List<int> bytes = workbook.saveAsStream();

    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: 'tank_report',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> exportToPdf(List<TankDataModel> tanks) async {

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
                        'Overall Tank Reports',
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

                // Tank Details in a grid layout - ADDED Product filter
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Region', _selectedRegion),
                          _buildDetailRow('Product', _selectedProduct), // ADDED this
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
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

          pw.Table.fromTextArray(
            headers: [
              'Site',
              'Tank Id',
              'Product', // ADDED this
              'Level',
              'Pressure',
              'Battery',
              'Solar',
              'Status',
            ],
            data: tanks.map((tank) {
              return [
                tank.siteName,
                tank.tankName,
                tank.gasType, // ADDED this
                '${tank.level.toString()}%',
                '${tank.pressure.toString()} Bar',
                '${tank.batteryV.toString()} V',
                '${tank.solarV.toString()} V',
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