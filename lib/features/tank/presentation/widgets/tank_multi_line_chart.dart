import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../data/model/tank_reading_model.dart';


class TankMultiLineChart extends StatefulWidget {
  final List<TankReadingModel> data;
  final String tankName;

  const TankMultiLineChart({
    super.key,
    required this.data,
    this.tankName = 'Tank',
  });

  @override
  State<TankMultiLineChart> createState() => _TankMultiLineChartState();
}

class _TankMultiLineChartState extends State<TankMultiLineChart> {
  late TrackballBehavior _trackball;
  late ZoomPanBehavior _zoomPan;

  // Toggle visibility per series
  bool _showLevel = true;
  bool _showPressure = true;
  bool _showBattery = true;
  bool _showSolar = true;

  @override
  void initState() {
    super.initState();

    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode:
      TrackballDisplayMode.groupAllPoints,
      lineType: TrackballLineType.vertical,
      lineColor: Colors.grey.withValues(alpha: 0.5),
      lineWidth: 1,
      tooltipSettings: InteractiveTooltip(
        enable: true,
        color: const Color(0xFF1E293B),
        borderWidth: 0,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    _zoomPan = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 315,
          child: SfCartesianChart(
            trackballBehavior: _trackball,
            zoomPanBehavior: _zoomPan,
            plotAreaBorderWidth: 0,

            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelPlacement: LabelPlacement.onTicks,
              // Show fewer labels to avoid crowding
              desiredIntervals: 6,
            ),

            primaryYAxis: NumericAxis(
              labelStyle: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: MajorGridLines(
                width: 0.5,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
              ),
            ),

            // No built-in legend — we render our own below
            legend: const Legend(isVisible: false),

            tooltipBehavior: TooltipBehavior(enable: false),

            series: <CartesianSeries>[
              if (_showLevel)
                LineSeries<TankReadingModel, String>(
                  name: 'Level',
                  dataSource: widget.data,
                  xValueMapper: (d, _) => d.time,
                  yValueMapper: (d, _) => d.level,
                  color: Colors.green,
                  width: 2,
                  // Subtle fill under level line
                  enableTooltip: true,
                  markerSettings: MarkerSettings(
                    isVisible: widget.data.length <= 24,
                    height: 5,
                    width: 5,
                    shape: DataMarkerType.circle,
                    color: Colors.green,
                    borderWidth: 0,
                  ),
                ),

              if (_showPressure)
                LineSeries<TankReadingModel, String>(
                  name: 'Pressure',
                  dataSource: widget.data,
                  xValueMapper: (d, _) => d.time,
                  yValueMapper: (d, _) => d.pressure,
                  color: Colors.blue,
                  width: 1.5,
                  dashArray: const [5, 4],
                  enableTooltip: true,
                  markerSettings: MarkerSettings(
                    isVisible: widget.data.length <= 24,
                    height: 4,
                    width: 4,
                    shape: DataMarkerType.circle,
                    color: Colors.blue,
                    borderWidth: 0,
                  ),
                ),

              if (_showBattery)
                LineSeries<TankReadingModel, String>(
                  name: 'Battery',
                  dataSource: widget.data,
                  xValueMapper: (d, _) => d.time,
                  yValueMapper: (d, _) => d.battery,
                  color: const Color(0xFF7F77DD),
                  width: 1.5,
                  dashArray: const [3, 3],
                  enableTooltip: true,
                  markerSettings: MarkerSettings(
                    isVisible: widget.data.length <= 24,
                    height: 4,
                    width: 4,
                    shape: DataMarkerType.diamond,
                    color: const Color(0xFF7F77DD),
                    borderWidth: 0,
                  ),
                ),

              if (_showSolar)
                LineSeries<TankReadingModel, String>(
                  name: 'Solar',
                  dataSource: widget.data,
                  xValueMapper: (d, _) => d.time,
                  yValueMapper: (d, _) => d.solar,
                  color: const Color(0xFFBA7517),
                  width: 1.5,
                  enableTooltip: true,
                  markerSettings: MarkerSettings(
                    isVisible: widget.data.length <= 24,
                    height: 4,
                    width: 4,
                    shape: DataMarkerType.circle,
                    color: const Color(0xFFBA7517),
                    borderWidth: 0,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Custom tap-to-toggle legend
        Center(
          child: _CustomLegend(
            showLevel: _showLevel,
            showPressure: _showPressure,
            showBattery: _showBattery,
            showSolar: _showSolar,
            onToggle: (series) {
              setState(() {
                if (series == 'Level') _showLevel = !_showLevel;
                if (series == 'Pressure') _showPressure = !_showPressure;
                if (series == 'Battery') _showBattery = !_showBattery;
                if (series == 'Solar') _showSolar = !_showSolar;
              });
            },
          ),
        ),
      ],
    );
  }
}


// ── Tap-to-toggle legend ─────────────────────────────────────────────

class _CustomLegend extends StatelessWidget {
  final bool showLevel, showPressure, showBattery, showSolar;
  final void Function(String) onToggle;

  const _CustomLegend({
    required this.showLevel,
    required this.showPressure,
    required this.showBattery,
    required this.showSolar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 26,
      runSpacing: 8,
      children: [
        _LegendItem('Level',    const Color(0xFF1D9E75), showLevel,    onToggle),
        _LegendItem('Pressure', const Color(0xFF378ADD), showPressure, onToggle),
        _LegendItem('Battery',  const Color(0xFF7F77DD), showBattery,  onToggle),
        _LegendItem('Solar',    const Color(0xFFBA7517), showSolar,    onToggle),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool visible;
  final void Function(String) onToggle;

  const _LegendItem(this.label, this.color, this.visible, this.onToggle);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: visible ? color : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: visible
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                  : Colors.grey.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}