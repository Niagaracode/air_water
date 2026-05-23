import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/app_theme/app_theme.dart';
import '../../controller/tank_readings_provider.dart';
import '../../widgets/tank_multi_line_chart.dart';

class TankDetailsTab extends ConsumerWidget {
  final int tankId;
  final String day;

  const TankDetailsTab({
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

    /// Example channel data
    final channels = [
      {
        'icon': Icons.gas_meter_outlined,
        'description': 'Level',
        'channel': '1',
        'value': '93.6 % Full',
        'thresholds': 'R: <= 40 %    C: <= 30 %',
      },
      {
        'icon': Icons.speed,
        'description': 'Pressure',
        'channel': '2',
        'value': '10.53 Bar',
        'thresholds': 'Low: <= 15 Bar',
      },
      {
        'icon': Icons.battery_0_bar_rounded,
        'description': 'Battery',
        'channel': 'BATT_VOLTAGE',
        'value': '8.12 Volts',
        'thresholds': 'Low: <= 10 Volts',
      },
      {
        'icon': Icons.solar_power,
        'description': 'Solar',
        'channel': 'SOLAR_VOLTAGE',
        'value': '12.45 Volts',
        'thresholds': 'Low: <= 10 Volts',
      },
    ];

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 16, top: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            /// CHART
            SizedBox(
              height: 350,
              child: TankMultiLineChart(
                data: readingsState.readings,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Data Channels',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Spacer(),
                  TextButton.icon(
                    onPressed: () {},

                    icon: Icon(
                      Icons.mode_edit_sharp,
                      color: primary,
                      size: 18,
                    ),

                    label: Text(
                      'Edit Rule',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),

                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      backgroundColor: primary.withValues(alpha: 0.08),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: Container(
                height: 200,
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
                child: DataTable2(
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  minWidth: 800,
                  headingRowHeight: 35,
                  dataRowHeight: 40,
                  headingRowDecoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  columns: const [
                    DataColumn2(
                      label: Text(''),
                      fixedWidth: 40,
                    ),
                    DataColumn2(
                      label: Text('DESCRIPTION'),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('CHANNEL'),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('LAST READING'),
                      fixedWidth: 150,
                    ),
                    DataColumn2(
                      label: Text('READING TIME'),
                      fixedWidth: 150,
                    ),
                    DataColumn2(
                      label: Text('THRESHOLDS'),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows: channels.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                        DataCell(
                          Text(item['description'] as String),
                        ),
                        DataCell(
                          Text(item['channel'] as String),
                        ),
                        DataCell(
                          Text(item['value'] as String),
                        ),
                        DataCell(
                          Text(day),
                        ),

                        DataCell(
                          Text(item['thresholds'] as String),
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
    );
  }
}

/*
class TankDetailsTab extends ConsumerWidget {

  final int tankId;
  final String day;

  const TankDetailsTab({
    super.key,
    required this.tankId, required this.day,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final readingsState = ref.watch(tankReadingsProvider(
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

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: TankMultiLineChart(
        data: readingsState.readings,
      ),
    );
  }
}*/
