import 'package:flutter/cupertino.dart';

class BatteryVisual extends StatelessWidget {
  final double percentage;

  const BatteryVisual({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final safePercentage =
    percentage.clamp(0.0, 1.0);

    Color color;

    if (safePercentage <= 0.20) {
      color = const Color(0xFFDC2626);
    } else if (safePercentage <= 0.40) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFF16A34A);
    }

    return Container(
      width: 48,
      height: 78,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF374151),
          width: 2,
        ),
        borderRadius:
        BorderRadius.circular(7),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: safePercentage,
          widthFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius:
              BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}