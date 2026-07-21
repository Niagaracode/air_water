import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small pill-shaped "tank" that fills with an animated, gently moving
/// liquid surface to represent the current level percentage.
class AnimatedTankLevel extends StatefulWidget {
  const AnimatedTankLevel({
    super.key,
    required this.level,
    required this.color,
    this.width = 42,
    this.height = 86,
  });

  /// 0-100
  final double level;
  final Color color;
  final double width;
  final double height;

  @override
  State<AnimatedTankLevel> createState() => _AnimatedTankLevelState();
}

class _AnimatedTankLevelState extends State<AnimatedTankLevel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedLevel = widget.level.clamp(0, 100).toDouble();
    final radius = widget.width / 2.4;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade300, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clampedLevel / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, fillFraction, _) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, __) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _LiquidPainter(
                  fillFraction: fillFraction,
                  wavePhase: _waveController.value * 2 * math.pi,
                  color: widget.color,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.fillFraction,
    required this.wavePhase,
    required this.color,
  });

  final double fillFraction;
  final double wavePhase;
  final Color color;

  static const double _waveAmplitude = 3.2;

  @override
  void paint(Canvas canvas, Size size) {
    final fillHeight = size.height * (1 - fillFraction);

    Path buildWavePath(double phaseShift, double amplitude) {
      final path = Path()..moveTo(0, size.height);
      path.lineTo(0, fillHeight);
      const step = 4.0;
      for (double x = 0; x <= size.width; x += step) {
        final y = fillHeight +
            amplitude *
                math.sin((x / size.width * 2 * math.pi) + wavePhase + phaseShift);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, fillHeight);
      path.lineTo(size.width, size.height);
      path.close();
      return path;
    }

    final backWave = buildWavePath(math.pi / 2, _waveAmplitude * 0.7);
    final frontWave = buildWavePath(0, _waveAmplitude);

    canvas.drawPath(backWave, Paint()..color = color.withValues(alpha: 0.35));
    canvas.drawPath(frontWave, Paint()..color = color.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color;
  }
}