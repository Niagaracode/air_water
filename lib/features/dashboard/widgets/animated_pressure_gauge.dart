import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A semi-circular gauge that sweeps to the given percentage with a smooth
/// animation whenever the value changes, used to represent tank pressure.
class AnimatedPressureGauge extends StatelessWidget {
  const AnimatedPressureGauge({
    super.key,
    required this.percentage,
    required this.valueLabel,
    required this.color,
    this.diameter = 92,
  });

  /// 0-100 (values above 100 are visually clamped, but the raw value can
  /// still be used by the caller to decide the color, e.g. over-pressure).
  final double percentage;
  final String valueLabel;
  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100).toDouble();
    final strokeWidth = diameter * 0.15;
    final arcHeight = diameter / 2 + strokeWidth;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, fraction, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size(diameter, arcHeight),
              painter: _GaugePainter(
                fraction: fraction,
                strokeWidth: strokeWidth,
                color: color,
              ),
            ),
            Transform.translate(
              offset: Offset(0, -arcHeight * 0.38),
              child: Text(
                valueLabel,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.strokeWidth,
    required this.color,
  });

  final double fraction;
  final double strokeWidth;
  final Color color;

  static const double _startAngle = math.pi; // left side (180deg)
  static const double _sweep = math.pi; // half circle (180deg)

  @override
  void paint(Canvas canvas, Size size) {
    final arcRect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.width - strokeWidth,
    );

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: _startAngle,
        endAngle: _startAngle + _sweep,
        colors: [color.withValues(alpha: 0.45), color],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, _startAngle, _sweep, false, bgPaint);
    canvas.drawArc(arcRect, _startAngle, _sweep * fraction, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.color != color;
  }
}