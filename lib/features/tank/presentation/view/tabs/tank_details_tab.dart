import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/tank_readings_provider.dart';
import '../../widgets/tank_multi_line_chart.dart';


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
}