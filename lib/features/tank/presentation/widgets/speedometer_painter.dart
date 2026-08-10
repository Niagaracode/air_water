import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedometerPainter extends CustomPainter {
  final double value;
  final double maxValue;

  SpeedometerPainter({
    required this.value,
    required this.maxValue,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height * 0.90,
    );

    final radius = size.width * 0.40;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    // ==========================================================
    // BACKGROUND ARC
    // ==========================================================

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE5E7EB);

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // ==========================================================
    // VALUE ARC
    // ==========================================================

    final percentage =
    (value / maxValue).clamp(0.0, 1.0);

    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = _getPressureColor(
        percentage,
      );

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * percentage,
      false,
      valuePaint,
    );

    // ==========================================================
    // TICKS
    // ==========================================================

    final tickPaint = Paint()
      ..strokeWidth = 1.5
      ..color = Colors.grey.shade500;

    for (int i = 0; i <= 10; i++) {
      final tickPercentage = i / 10;

      final angle =
          math.pi + (math.pi * tickPercentage);

      final outerPoint = Offset(
        center.dx +
            math.cos(angle) *
                (radius + 10),
        center.dy +
            math.sin(angle) *
                (radius + 10),
      );

      final innerPoint = Offset(
        center.dx +
            math.cos(angle) *
                (radius + 3),
        center.dy +
            math.sin(angle) *
                (radius + 3),
      );

      canvas.drawLine(
        innerPoint,
        outerPoint,
        tickPaint,
      );
    }

    // ==========================================================
    // NEEDLE
    // ==========================================================

    final needleAngle =
        math.pi +
            (math.pi * percentage);

    final needleLength =
        radius - 15;

    final needleEnd = Offset(
      center.dx +
          math.cos(needleAngle) *
              needleLength,
      center.dy +
          math.sin(needleAngle) *
              needleLength,
    );

    final needlePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      needleEnd,
      needlePaint,
    );

    // Center circle
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = const Color(0xFF111827),
    );
  }

  Color _getPressureColor(
      double percentage,
      ) {
    if (percentage >= 0.85) {
      return const Color(0xFFDC2626);
    }

    if (percentage >= 0.60) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF2563EB);
  }

  @override
  bool shouldRepaint(
      covariant SpeedometerPainter oldDelegate,
      ) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue;
  }
}