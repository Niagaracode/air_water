import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdfLib;
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;

import '../../../../core/helpers/date_formatter.dart';
import '../../../config/app_config.dart';
import '../../tank/data/model/tank_reading_model.dart';
import '../data/models/tank_data_model.dart';

class TankReadingsReportExporter {
  TankReadingsReportExporter._();

  static Future<void> exportExcel({
    required List<TankReadingModel> readings,
    required TankDataModel tank,
    required String reportTitle,
  }) async {
    final workbook = xls.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Tank Report';

    // ---- Title ----
    final titleRange = sheet.getRangeByName('A1:G2');
    titleRange.merge();
    titleRange.setText('TANK READINGS REPORT');
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontSize = 20;
    titleRange.cellStyle.fontColor = '#FFFFFF';
    titleRange.cellStyle.backColor = '#1F4E78';
    titleRange.cellStyle.hAlign = xls.HAlignType.center;
    titleRange.cellStyle.vAlign = xls.VAlignType.center;

    // ---- Report info ----
    sheet.getRangeByName('A4').setText('Site Name');
    sheet.getRangeByName('B4').setText(tank.siteName);

    sheet.getRangeByName('A5').setText('Product Name');
    sheet.getRangeByName('B5').setText('${tank.tankName}(${tank.gasType})');

    sheet.getRangeByName('A6').setText('Device ID');
    sheet.getRangeByName('B6').setText(tank.deviceId);

    sheet.getRangeByName('D5').setText('Generated On');
    sheet.getRangeByName('E5').setText(
      DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
    );

    sheet.getRangeByName('D6').setText('Total Readings');
    sheet.getRangeByName('E6').setText(readings.length.toString());

    for (final cell in ['A4', 'A5', 'A6', 'D5', 'D6']) {
      sheet.getRangeByName(cell).cellStyle.bold = true;
    }

    // ---- Table header ----
    const headerRow = 8;
    final headers = ['Date Time', 'Time', 'Level (%)', 'Pressure (Bar)', 'Battery (V)', 'Solar (V)', 'Volume (L)'];

    final headerStyle = workbook.styles.add('readingsHeaderStyle');
    headerStyle.bold = true;
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.backColor = '#4472C4';
    headerStyle.hAlign = xls.HAlignType.center;
    headerStyle.vAlign = xls.VAlignType.center;
    headerStyle.borders.all.lineStyle = xls.LineStyle.thin;
    headerStyle.borders.all.color = '#B0BEC5';

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.getRangeByIndex(headerRow, col + 1);
      cell.setText(headers[col]);
      cell.cellStyle = headerStyle;
    }
    sheet.getRangeByIndex(headerRow, 1, headerRow, 7).rowHeight = 22;

    // ---- Data ----
    final dataStyle = workbook.styles.add('readingsDataStyle');
    dataStyle.fontSize = 10;
    dataStyle.vAlign = xls.VAlignType.center;
    dataStyle.borders.all.lineStyle = xls.LineStyle.thin;
    dataStyle.borders.all.color = '#E0E0E0';

    final altStyle = workbook.styles.add('readingsAltStyle');
    altStyle.fontSize = 10;
    altStyle.vAlign = xls.VAlignType.center;
    altStyle.borders.all.lineStyle = xls.LineStyle.thin;
    altStyle.borders.all.color = '#E0E0E0';
    altStyle.backColor = '#F8F9FA';

    for (int i = 0; i < readings.length; i++) {
      final row = headerRow + 1 + i;
      final item = readings[i];
      final style = i.isEven ? dataStyle : altStyle;

      sheet.getRangeByIndex(row, 1)..setText(DateFormatter.formatDateTime(item.createdAt))..cellStyle = style;
      sheet.getRangeByIndex(row, 2)..setText(item.time)..cellStyle = style;
      sheet.getRangeByIndex(row, 3)..setText(item.level.toString())..cellStyle = style;
      sheet.getRangeByIndex(row, 4)..setText(item.pressure.toString())..cellStyle = style;
      sheet.getRangeByIndex(row, 5)..setText(item.battery.toString())..cellStyle = style;
      sheet.getRangeByIndex(row, 6)..setText(item.solar.toString())..cellStyle = style;
      sheet.getRangeByIndex(row, 7)..setText(item.volume.toString())..cellStyle = style;

      sheet.getRangeByIndex(row, 1, row, 7).rowHeight = 18;
    }

    // Freeze right below the table header
    sheet.getRangeByIndex(headerRow + 1, 1).freezePanes();

    for (int i = 1; i <= 7; i++) {
      sheet.autoFitColumn(i);
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: reportTitle,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Future<void> exportPdf({
    required List<TankReadingModel> readings,
    required TankDataModel tank,
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
                'Generated by AirWater System',
                style: pw.TextStyle(fontSize: 8, color: pdfLib.PdfColors.grey600),
              ),
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
                        'Tank Readings Report',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
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
                          _buildDetailRow('Site Name', tank.siteName),
                          _buildDetailRow('Tank Id & Gas', '${tank.tankName}(${tank.gasType})'),
                          _buildDetailRow('Device SNo', tank.deviceId),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('City', tank.city),
                          _buildDetailRow('Generated On',
                              DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now())),
                          _buildDetailRow('Total Readings', readings.length.toString()),
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
              0: const pw.FlexColumnWidth(2.2), // Date Time
              1: const pw.FlexColumnWidth(1.4), // Level
              2: const pw.FlexColumnWidth(1.6), // Pressure
              3: const pw.FlexColumnWidth(1.4), // Battery
              4: const pw.FlexColumnWidth(1.4), // Solar
              5: const pw.FlexColumnWidth(1.4), // Volume
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: pdfLib.PdfColors.blue),
                children: ['Date Time', 'Level', 'Pressure', 'Battery', 'Solar', 'Volume']
                    .map((h) => pw.Container(
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
                ))
                    .toList(),
              ),
              ...readings.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final bg = index.isEven ? pdfLib.PdfColors.white : pdfLib.PdfColors.grey100;

                final cells = [
                  DateFormatter.formatDateTime(item.createdAt),
                  '${item.level}%',
                  '${item.pressure} Bar',
                  '${item.battery} V',
                  '${item.solar} V',
                  '${item.volume} L',
                ];

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: cells
                      .map((v) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      v,
                      style: pw.TextStyle(fontSize: 9, color: pdfLib.PdfColors.grey900),
                    ),
                  ))
                      .toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await FileSaver.instance.saveFile(
      name: '${tank.tankName}_readings_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
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
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfLib.PdfColors.grey700),
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