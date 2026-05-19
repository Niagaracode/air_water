import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/model/tank_reading_model.dart';

class TankMultiLineChart extends StatelessWidget {

  final List<TankReadingModel> data;

  const TankMultiLineChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {

    return SfCartesianChart(

      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),

      tooltipBehavior: TooltipBehavior(
        enable: true,
      ),

      primaryXAxis: CategoryAxis(),

      series: <CartesianSeries>[

        LineSeries<TankReadingModel, String>(
          name: 'Level',
          dataSource: data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.level,

          markerSettings: const MarkerSettings(
            isVisible: true,
          ),
        ),

        LineSeries<TankReadingModel, String>(
          name: 'Pressure',
          dataSource: data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.pressure,

          markerSettings: const MarkerSettings(
            isVisible: true,
          ),
        ),

        LineSeries<TankReadingModel, String>(
          name: 'Battery',
          dataSource: data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.battery,

          markerSettings: const MarkerSettings(
            isVisible: true,
          ),
        ),

        LineSeries<TankReadingModel, String>(
          name: 'Solar',
          dataSource: data,
          xValueMapper: (d, _) => d.time,
          yValueMapper: (d, _) => d.solar,

          markerSettings: const MarkerSettings(
            isVisible: true,
          ),
        ),
      ],
    );
  }
}