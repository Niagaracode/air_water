import 'dart:math' as math;
import 'package:flutter/material.dart';

class GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final double startAngle;
  final double sweepAngle;

  GaugePainter({
    required this.value,
    required this.maxValue,
    required this.startAngle,
    required this.sweepAngle,
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

    // Background
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE5E7EB);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    final percentage =
    (value / maxValue).clamp(0.0, 1.0);

    // Value
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = _getLevelColor(
        percentage,
      );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * percentage,
      false,
      valuePaint,
    );

    // Tick marks
    final tickPaint = Paint()
      ..strokeWidth = 1.5
      ..color = Colors.grey.shade500;

    for (int i = 0; i <= 10; i++) {
      final tickValue = i / 10;

      final angle =
          startAngle +
              (sweepAngle * tickValue);

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
  }

  Color _getLevelColor(
      double percentage,
      ) {
    if (percentage <= 0.20) {
      return const Color(0xFFDC2626);
    }

    if (percentage <= 0.40) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF16A34A);
  }

  @override
  bool shouldRepaint(
      covariant GaugePainter oldDelegate,
      ) {
    return oldDelegate.value != value;
  }
}