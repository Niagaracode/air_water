import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/helpers/date_formatter.dart';
import '../../controller/tank_readings_provider.dart';
import 'package:data_table_2/data_table_2.dart';


class TankReadingsTab extends ConsumerWidget {
  final int tankId;
  final String? day;
  final DateTime? startDate;
  final DateTime? endDate;

  const TankReadingsTab({
    super.key,
    required this.tankId,
    required this.day,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsState = ref.watch(tankReadingsProvider(
      TankReadingParams(
        tankId: tankId,
        day: day,
        startDate: startDate,
        endDate: endDate,
      ),
    ));

    if (readingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (readingsState.readings.isEmpty) {
      return const Center(child: Text('No readings available'));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 16,
            minWidth: 1200,

            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFF9FAFB),
            ),

            headingRowHeight: 48,
            dataRowHeight: 42,

            dividerThickness: 0,

            headingTextStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.3,
            ),

            dataTextStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF374151),
            ),

            columns: const [
              DataColumn2(label: Text('READING AT'), size: ColumnSize.L),
              DataColumn2(label: Text('LEVEL'), size: ColumnSize.S),
              DataColumn2(label: Text('PRESSURE'), size: ColumnSize.S),
              DataColumn2(label: Text('BATTERY'), size: ColumnSize.S),
              DataColumn2(label: Text('SOLAR'), size: ColumnSize.S),
            ],

            rows: readingsState.readings.asMap().entries.map((entry) {
              final index = entry.key;
              final reading = entry.value;
              final isEven = index % 2 == 0;

              return DataRow2(
                color: WidgetStateProperty.all(
                  isEven ? Colors.white : const Color(0xFFF6F7FB),
                ),
                cells: [
                  DataCell(
                    Text(
                      DateFormatter.formatDateTime(reading.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${reading.level} %',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${reading.pressure} bar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${reading.battery} v',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${reading.solar} v',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}