import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdfLib;
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

import '../../../../config/app_config.dart';
import '../data/models/tank_data_model.dart';

class TankReportExporter {
  TankReportExporter._(); // no instances, pure static helper

  /// Single source of truth for filtering — used by list view AND exports.
  static List<TankDataModel> applyFilters(
      List<TankDataModel> tanks, {
        required String selectedStatus,
        required String selectedRegion,
        required String selectedProduct,
        required String searchQuery,
      }) {
    return tanks.where((tank) {
      final matchesStatus =
          selectedStatus == 'All Status' || tank.status == selectedStatus;

      final matchesRegion =
          selectedRegion == 'All Regions' || tank.region == selectedRegion; // adjust field name if different

      final matchesProduct =
          selectedProduct == 'All Product' || tank.gasType == selectedProduct;

      final matchesSearch = searchQuery.isEmpty ||
          tank.tankName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tank.siteName.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesStatus && matchesRegion && matchesProduct && matchesSearch;
    }).toList();
  }

  static bool hasActiveFilters({
    required String selectedStatus,
    required String selectedRegion,
    required String selectedProduct,
    required String searchQuery,
  }) {
    return selectedStatus != 'All Status' ||
        selectedRegion != 'All Regions' ||
        selectedProduct != 'All Product' ||
        searchQuery.isNotEmpty;
  }

  /// Call this from the popup menu — it filters (if needed) and exports.
  static Future<void> export({
    required String format, // 'excel' | 'pdf'
    required List<TankDataModel> allTanks,
    required String selectedStatus,
    required String selectedRegion,
    required String selectedProduct,
    required String searchQuery,
  }) async {
    final active = hasActiveFilters(
      selectedStatus: selectedStatus,
      selectedRegion: selectedRegion,
      selectedProduct: selectedProduct,
      searchQuery: searchQuery,
    );

    final tanksToExport = active ? applyFilters(
      allTanks,
      selectedStatus: selectedStatus,
      selectedRegion: selectedRegion,
      selectedProduct: selectedProduct,
      searchQuery: searchQuery,
    ) : allTanks;

    if (format == 'excel') {
      await _exportToExcel(
        tanksToExport,
        selectedStatus: selectedStatus,
        selectedRegion: selectedRegion,
        selectedProduct: selectedProduct,
        searchQuery: searchQuery,
      );
    } else if (format == 'pdf') {
      await _exportToPdf(
        tanksToExport,
        selectedRegion: selectedRegion,
        selectedProduct: selectedProduct,
      );
    }
  }

  static Future<void> _exportToExcel(
      List<TankDataModel> tanks, {
        required String selectedStatus,
        required String selectedRegion,
        required String selectedProduct,
        required String searchQuery,
      }) async {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];

    final headers = [
      'Tank Name', 'Site', 'Product', 'Level (%)', 'Pressure (Bar)',
      'Battery (V)', 'Solar (V)', 'Status',
    ];

    // ---- Info block (rows 1-3) ----
    final titleStyle = workbook.styles.add('titleStyle');
    titleStyle.bold = true;
    titleStyle.fontSize = 14;
    titleStyle.fontColor = '#1E88E5';

    final infoLabelStyle = workbook.styles.add('infoLabelStyle');
    infoLabelStyle.bold = true;
    infoLabelStyle.fontSize = 10;
    infoLabelStyle.fontColor = '#555555';

    final infoValueStyle = workbook.styles.add('infoValueStyle');
    infoValueStyle.fontSize = 10;
    infoValueStyle.fontColor = '#000000';

    sheet.getRangeByName('A1').setText('Tank Report');
    sheet.getRangeByName('A1').cellStyle = titleStyle;
    sheet.getRangeByName('A1:H1').merge();

    sheet.getRangeByName('A2').setText('Generated On:');
    sheet.getRangeByName('A2').cellStyle = infoLabelStyle;
    sheet.getRangeByName('B2').setText(
      DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
    );
    sheet.getRangeByName('B2').cellStyle = infoValueStyle;
    sheet.getRangeByName('B2:H2').merge();

    final filterParts = <String>[];
    if (selectedRegion != 'All Regions') filterParts.add('Region: $selectedRegion');
    if (selectedProduct != 'All Product') filterParts.add('Product: $selectedProduct');
    if (selectedStatus != 'All Status') filterParts.add('Status: $selectedStatus');
    if (searchQuery.isNotEmpty) filterParts.add('Search: "$searchQuery"');

    sheet.getRangeByName('A3').setText('Filters Applied:');
    sheet.getRangeByName('A3').cellStyle = infoLabelStyle;
    sheet.getRangeByName('B3').setText(
      filterParts.isEmpty ? 'None (showing all records)' : filterParts.join('  |  '),
    );
    sheet.getRangeByName('B3').cellStyle = infoValueStyle;
    sheet.getRangeByName('B3:H3').merge();

    sheet.getRangeByName('A1:H3').rowHeight = 20;

    // ---- Header row (now row 5, with a blank spacer row 4) ----
    const headerRow = 5;
    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.backColor = '#1E88E5';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.fontSize = 11;
    headerStyle.hAlign = xls.HAlignType.center;
    headerStyle.vAlign = xls.VAlignType.center;
    headerStyle.borders.all.lineStyle = xls.LineStyle.thin;
    headerStyle.borders.all.color = '#B0BEC5';

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.getRangeByIndex(headerRow, col + 1);
      cell.setText(headers[col]);
      cell.cellStyle = headerStyle;
    }
    sheet.getRangeByIndex(headerRow, 1, headerRow, 8).rowHeight = 22;

    // ---- Data rows (starting row 6) ----
    final dataStyle = workbook.styles.add('dataStyle');
    dataStyle.fontSize = 10;
    dataStyle.borders.all.lineStyle = xls.LineStyle.thin;
    dataStyle.borders.all.color = '#E0E0E0';
    dataStyle.vAlign = xls.VAlignType.center;

    final altStyle = workbook.styles.add('altStyle');
    altStyle.fontSize = 10;
    altStyle.borders.all.lineStyle = xls.LineStyle.thin;
    altStyle.borders.all.color = '#E0E0E0';
    altStyle.vAlign = xls.VAlignType.center;
    altStyle.backColor = '#F5F7FA';

    for (int i = 0; i < tanks.length; i++) {
      final row = headerRow + 1 + i;
      final tank = tanks[i];
      final style = i.isEven ? dataStyle : altStyle;

      sheet.getRangeByIndex(row, 1)..setText(tank.tankName)..cellStyle = style;
      sheet.getRangeByIndex(row, 2)..setText(tank.siteName)..cellStyle = style;
      sheet.getRangeByIndex(row, 3)..setText(tank.gasType)..cellStyle = style;
      sheet.getRangeByIndex(row, 4)..setNumber(tank.level)..cellStyle = style;
      sheet.getRangeByIndex(row, 5)..setNumber(tank.pressure)..cellStyle = style;
      sheet.getRangeByIndex(row, 6)..setNumber(tank.batteryV)..cellStyle = style;
      sheet.getRangeByIndex(row, 7)..setNumber(tank.solarV)..cellStyle = style;
      sheet.getRangeByIndex(row, 8)..setText(tank.status)..cellStyle = style;

      sheet.getRangeByIndex(row, 1, row, 8).rowHeight = 18;
    }

    // Freeze everything above and including the header row
    sheet.getRangeByIndex(headerRow + 1, 1).freezePanes();

    for (var col = 1; col <= 8; col++) {
      sheet.autoFitColumn(col);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: 'tank_report',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }


  static Future<void> _exportToPdf(
      List<TankDataModel> tanks, {
        required String selectedRegion,
        required String selectedProduct,
      }) async {
    final pdf = pw.Document();

    final svgLogo = await rootBundle.loadString(
      AppConfig.current.companyLogoPath,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdfLib.PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: pdfLib.PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SvgImage(svg: svgLogo, fit: pw.BoxFit.contain, height: 12),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: pdfLib.PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: pdfLib.PdfColors.blue, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  decoration: const pw.BoxDecoration(),
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
                      pw.SvgImage(svg: svgLogo, fit: pw.BoxFit.contain, height: 25),
                    ],
                  ),
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Region', selectedRegion),
                          _buildDetailRow('Product', selectedProduct),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Generated On',
                            DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
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

          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: pdfLib.PdfColors.grey300, width: 0.5),
              bottom: pw.BorderSide(color: pdfLib.PdfColors.grey300, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2), // Site
              1: const pw.FlexColumnWidth(1.6), // Tank Id
              2: const pw.FlexColumnWidth(1.6), // Product
              3: const pw.FlexColumnWidth(1.2), // Level
              4: const pw.FlexColumnWidth(1.4), // Pressure
              5: const pw.FlexColumnWidth(1.2), // Battery
              6: const pw.FlexColumnWidth(1.2), // Solar
              7: const pw.FlexColumnWidth(1.4), // Status
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: pdfLib.PdfColors.blue),
                children: [
                  'Site',
                  'Tank Id',
                  'Product',
                  'Level',
                  'Pressure',
                  'Battery',
                  'Solar',
                  'Status',
                ].map((h) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: pdfLib.PdfColors.white,
                    ),
                  ),
                )).toList(),
              ),
              // Data rows
              ...tanks.asMap().entries.map((entry) {
                final index = entry.key;
                final tank = entry.value;
                final bg = index.isEven ? pdfLib.PdfColors.white : pdfLib.PdfColors.grey100;

                final cells = [
                  tank.siteName,
                  tank.tankName,
                  tank.gasType,
                  '${tank.level}%',
                  '${tank.pressure} Bar',
                  '${tank.batteryV} V',
                  '${tank.solarV} V',
                  tank.status,
                ];

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: cells.asMap().entries.map((c) {
                    final isNumericCol = c.key >= 3; // Level, Pressure, Battery, Solar, Status columns right-ish
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      alignment: isNumericCol ? pw.Alignment.centerLeft : pw.Alignment.centerLeft,
                      child: pw.Text(
                        c.value,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: pdfLib.PdfColors.grey900,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
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

  static pw.Widget _buildDetailRow(String label, String value) {
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
          pw.Text(': ', style: pw.TextStyle(fontSize: 11, color: pdfLib.PdfColors.grey500)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfLib.PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }
}