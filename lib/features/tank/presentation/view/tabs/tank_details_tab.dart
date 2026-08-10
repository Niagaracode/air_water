import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/tank_readings_provider.dart';
import '../../widgets/tank_multi_line_chart.dart';

class TankDetailsTab extends ConsumerWidget {
  final int tankId;
  final String? day;
  final DateTime? startDate;
  final DateTime? endDate;

  const TankDetailsTab({
    super.key,
    required this.tankId,
    required this.day,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final readingsState = ref.watch(
      tankReadingsProvider(
        TankReadingParams(
          tankId: tankId,
          day: day,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

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
        child: SizedBox(
          height: 470,
          child: TankMultiLineChart(
            data: readingsState.readings,
          ),
        ),
      ),
    );
  }
}