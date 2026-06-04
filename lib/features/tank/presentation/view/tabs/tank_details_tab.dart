import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_theme/app_theme.dart';
import '../../../data/model/tank_channel_model.dart';
import '../../controller/tank_channel_provider.dart';
import '../../controller/tank_provider.dart';
import '../../controller/tank_readings_provider.dart';
import '../../widgets/tank_multi_line_chart.dart';
import '../threshold_side_sheet.dart';

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
        TankReadingParams(tankId: tankId, day: day),
      ),
    );

    final channelState = ref.watch(tankChannelProvider(tankId));

    if (readingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (readingsState.readings.isEmpty) {
      return const Center(child: Text('No readings available'));
    }

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 16, top: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
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
                                  await tankRepository.updateTankChannelEvent(tankId, payload);

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
                child: channelState.isLoading ? Center(
                  child: CircularProgressIndicator(),
                ) : DataTable2(
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
                      label: Text('CHANNEL'),
                      fixedWidth: 70,
                    ),

                    DataColumn2(
                      label: Text('DESCRIPTION'),
                      size: ColumnSize.M,
                    ),

                    DataColumn2(
                      label: Text('LAST READING'),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('READING TIME'),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Text('THRESHOLDS'),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows: channelState.channels.map((item) {
                    return DataRow(
                      cells: [

                        DataCell(
                          Center(child: Text(item.id.toString())),
                        ),

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
    );
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

}