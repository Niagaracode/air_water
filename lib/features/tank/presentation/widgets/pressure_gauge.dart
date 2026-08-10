import 'package:air_water/features/tank/presentation/widgets/speedometer_painter.dart';
import 'package:flutter/material.dart';

class PressureGauge extends StatelessWidget {
  final double value;

  const PressureGauge({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    //
    // Adjust this maximum according to your
    // actual pressure sensor range.
    //
    const maxPressure = 20.0;

    final safeValue = value.clamp(
      0.0,
      maxPressure,
    );

    return Center(
      child: SizedBox(
        width: 180,
        height: 115,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(
                180,
                115,
              ),
              painter: SpeedometerPainter(
                value: safeValue,
                maxValue: maxPressure,
              ),
            ),

            Positioned(
              top: 45,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: safeValue,
                ),
                duration:
                const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (
                    context,
                    animatedValue,
                    child,
                    ) {
                  return Column(
                    children: [
                      Text(
                        animatedValue.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const Text(
                        'BAR',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Positioned(
              left: 4,
              bottom: 3,
              child: Text(
                '0',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
              ),
            ),

            const Positioned(
              right: 0,
              bottom: 3,
              child: Text(
                '20',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}