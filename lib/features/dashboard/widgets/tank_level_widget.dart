import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/helpers/app_colors_helper.dart';
import 'dart:math' as math;

class TankLevelWidget extends StatefulWidget {
  final double level;
  final String svgAsset;
  final String gasType;

  const TankLevelWidget({
    super.key,
    required this.level,
    required this.svgAsset,
    required this.gasType,
  });

  @override
  State<TankLevelWidget> createState() => _TankLevelWidgetState();
}

class _TankLevelWidgetState extends State<TankLevelWidget>
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
    const tankWidth = 120.0;
    const tankHeight = 200.0;
    // Height of the cylindrical body
    const liquidAreaHeight = 160.0;
    final color = AppColorsHelper.getGasTypeColor(widget.gasType);
    final clampedLevel = widget.level.clamp(0, 100).toDouble();

    return SizedBox(
      width: 160,
      height: tankHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          //--------------------------------------------------
          // ANIMATED WAVY LIQUID
          //--------------------------------------------------
          Positioned(
            left: -17.9,
            right: 22,
            bottom: 30,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 66,
                  height: liquidAreaHeight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: clampedLevel / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, fillFraction, _) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, __) {
                          return CustomPaint(
                            size: Size(66, liquidAreaHeight),
                            painter: _LiquidPainter(
                              fillFraction: fillFraction,
                              wavePhase: _waveController.value * 2 * math.pi,
                              color: color,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          //--------------------------------------------------
          // SVG (tank outline)
          //--------------------------------------------------
          SizedBox(
            width: tankWidth,
            height: tankHeight,
            child: SvgPicture.asset(
              widget.svgAsset,
              fit: BoxFit.contain,
            ),
          ),

          //--------------------------------------------------
          // PERCENTAGE BADGE
          //--------------------------------------------------
          Positioned(
            left: -17,
            right: 23,
            bottom: 30,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 70,
                  height: liquidAreaHeight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: clampedLevel / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, fillFraction, _) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, __) {
                          return CustomPaint(
                            size: Size(66, liquidAreaHeight),
                            painter: _LiquidPainter(
                              fillFraction: fillFraction,
                              wavePhase: _waveController.value * 2 * math.pi,
                              color: color,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          //--------------------------------------------------
          // PERCENTAGE BADGE
          //--------------------------------------------------
          Positioned(
            left: 100,
            top: tankHeight - 32 - (liquidAreaHeight * widget.level / 100) - 18,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColorsHelper.getGasTypeColor(widget.gasType),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "${widget.level.toStringAsFixed(0)} %",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          //--------------------------------------------------
          // SCALE
          //--------------------------------------------------
          Positioned(
            left: 72,
            top: 15,
            bottom: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("100", style: TextStyle(fontSize: 9)),
                Text("75", style: TextStyle(fontSize: 9)),
                Text("50", style: TextStyle(fontSize: 9)),
                Text("25", style: TextStyle(fontSize: 9)),
                Text("0", style: TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.fillFraction,
    required this.wavePhase,
    required this.color,
    this.bottomRadius = 10.0,
  });

  final double fillFraction;
  final double wavePhase;
  final Color color;
  final double bottomRadius;
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

    // Clip everything to a rounded-bottom rect so the liquid's own
    // shape curves into the tank base, not just the outer widget box.
    final clipRRect = RRect.fromRectAndCorners(
      Offset.zero & size,
      bottomLeft: Radius.circular(bottomRadius),
      bottomRight: Radius.circular(bottomRadius),
    );

    canvas.save();
    canvas.clipRRect(clipRRect);

    canvas.drawPath(
      backWave,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..blendMode = BlendMode.multiply,
    );
    canvas.drawPath(
      frontWave,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..blendMode = BlendMode.multiply,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.bottomRadius != bottomRadius;
  }
}