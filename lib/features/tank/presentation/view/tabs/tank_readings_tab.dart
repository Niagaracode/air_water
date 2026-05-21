import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../controller/tank_readings_provider.dart';
import 'package:data_table_2/data_table_2.dart';


class TankReadingsTab extends ConsumerWidget {
  final int tankId;
  final String day;

  const TankReadingsTab({
    super.key,
    required this.tankId,
    required this.day,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final readingsState = ref.watch(
      tankReadingsProvider(
        TankReadingParams(
          tankId: tankId,
          day: day,
        ),
      ),
    );


    if (readingsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (readingsState.readings.isEmpty) {
      return const Center(
        child: Text('No readings available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 8,
          minWidth: 1200,

          headingRowColor:
          WidgetStateProperty.all(
            const Color(0xFFF9FAFB),
          ),

          headingRowHeight: 50,
          dataRowHeight: 42,

          headingTextStyle:
          GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),

          dataTextStyle:
          GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF4B5563),
          ),

          columns: const [

            DataColumn2(
              label: Text('Reading At'),
              size: ColumnSize.L,
            ),

            DataColumn2(
              label: Text('Time'),
              size: ColumnSize.S,
            ),

            DataColumn2(
              label: Text('Level'),
              size: ColumnSize.S,
            ),

            DataColumn2(
              label: Text('Pressure'),
              size: ColumnSize.S,
            ),

            DataColumn2(
              label: Text('Battery'),
              size: ColumnSize.S,
            ),

            DataColumn2(
              label: Text('Solar'),
              size: ColumnSize.S,
            ),
          ],

          rows: readingsState.readings.map((reading) {
            return DataRow2(
              cells: [
                DataCell(
                  Text(
                    DateFormat(
                      'dd MMM yyyy hh:mm a',
                    ).format(
                      reading.createdAt,
                    ),
                  ),
                ),

                DataCell(
                  Text(reading.time),
                ),

                DataCell(
                  Text(
                    style: TextStyle(fontWeight: FontWeight.bold),
                    '${reading.level.toString()} %',
                  ),
                ),

                DataCell(
                  Text(
                    style: TextStyle(fontWeight: FontWeight.bold),
                    '${reading.pressure.toString()} bar',
                  ),
                ),

                DataCell(
                  Text(
                    style: TextStyle(fontWeight: FontWeight.bold),
                    '${reading.battery.toString()} v',
                  ),
                ),

                DataCell(
                  Text(
                    style: TextStyle(fontWeight: FontWeight.bold),
                    '${reading.solar.toString()} v',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}