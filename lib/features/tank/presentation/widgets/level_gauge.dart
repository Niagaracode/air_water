import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'gauge_painter.dart';

class LevelGauge extends StatelessWidget {
  final double value;

  const LevelGauge({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
    value.clamp(0.0, 100.0);

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
              painter: GaugePainter(
                value: safeValue,
                maxValue: 100,
                startAngle: math.pi,
                sweepAngle: math.pi,
              ),
            ),

            Positioned(
              top: 48,
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: safeValue,
                    ),
                    duration:
                    const Duration(milliseconds: 800),
                    builder: (
                        context,
                        animatedValue,
                        child,
                        ) {
                      return Text(
                        '${animatedValue.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),

                  const Text(
                    'LEVEL',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Positioned(
              left: 0,
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
                '100',
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