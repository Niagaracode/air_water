import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/helpers/app_colors_helper.dart';
import 'dart:math' as math;

class TankLevelWidget extends StatefulWidget {
  final double level;
  final String svgAsset;
  final String gasType;
  final double minLevel;
  final double maxLevel;

  const TankLevelWidget({
    super.key,
    required this.level,
    required this.svgAsset,
    required this.gasType,
    required this.minLevel,
    required this.maxLevel,
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
    // ============================================================
    // TANK SIZE
    // ============================================================

    const tankWidth = 160.0;
    const tankHeight = 280.0;

    // Actual gas area inside the tank
    const liquidAreaWidth = 100.0;
    const liquidAreaHeight = 210.0;

    final color = AppColorsHelper.getGasTypeColor(widget.gasType);
    final clampedLevel = widget.level.clamp(0, 100).toDouble();

    // ============================================================
    // SCALE CALCULATION
    // ============================================================

    const baseScaleTop = 25.0;
    const baseScaleBottom = 40.0;

    final scaleAvailableHeight = tankHeight - baseScaleTop - baseScaleBottom;
    final clampedMax = widget.maxLevel.clamp(0, 100).toDouble();
    final clampedMin = widget.minLevel.clamp(0, 100).toDouble();

    final scaleTop = baseScaleTop + ((100 - clampedMax) / 100) * scaleAvailableHeight;
    final scaleBottom = baseScaleBottom + (clampedMin / 100) * scaleAvailableHeight;

    // ============================================================
    // DISPLAY PERCENTAGE

    final levelRange = widget.maxLevel - widget.minLevel;

    final normalizedPercent = levelRange == 0 ? 0.0
        : ((widget.level - widget.minLevel) /
        levelRange * 100).clamp(0.0, 100.0);

    // ============================================================
    // TANK INTERNAL POSITIONS
    // ============================================================

    final liquidLeft = tankWidth * -0.00;
    final liquidRight = tankWidth * 0.00;
    final liquidBottom = tankHeight * 0.155;

    // ============================================================
    // SCALE HORIZONTAL POSITION
    // ============================================================

    final scaleLeft = tankWidth * 0.67;

    // ============================================================
    // BADGE POSITION
    // ============================================================

    final badgeLeft = tankWidth * 0.90;
    final badgeBottom = liquidBottom + (liquidAreaHeight * clampedLevel / 100) - 18;

    // ============================================================
    // TANK
    // ============================================================

    return SizedBox(
      width: tankWidth,
      height: tankHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          // ======================================================
          // 1. TANK SVG

          SizedBox(
            width: tankWidth,
            height: tankHeight,
            child: SvgPicture.asset(
              widget.svgAsset,
              fit: BoxFit.contain,
            ),
          ),

          // ======================================================
          // 2. ANIMATED GAS / LIQUID
          // ======================================================

          Positioned(
            left: liquidLeft,
            right: liquidRight,
            bottom: liquidBottom,
            child: ClipRRect(
              borderRadius:
              const BorderRadius.only(
                bottomLeft:
                Radius.circular(10),
                bottomRight:
                Radius.circular(10),
              ),
              child: Align(
                alignment:
                Alignment.bottomCenter,
                child: SizedBox(
                  width: liquidAreaWidth,
                  height: liquidAreaHeight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: clampedLevel / 100),
                    duration: const Duration(
                      milliseconds: 900,
                    ),
                    curve:
                    Curves.easeOutCubic,
                    builder: (context, fillFraction, _,) {
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, __,) {
                          return CustomPaint(
                            size: Size(
                              liquidAreaWidth,
                              liquidAreaHeight,
                            ),
                            painter: _LiquidPainter(
                              fillFraction:
                              fillFraction,
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

          // ======================================================
          // 3. PERCENTAGE BADGE
          // ======================================================

          Positioned(
            left: badgeLeft,
            bottom: badgeBottom,
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color: color,
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: Text("${normalizedPercent.toStringAsFixed(0)} %",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // ======================================================
          // 4. SCALE


          Positioned(
            left: scaleLeft,
            top: scaleTop,
            bottom: scaleBottom,
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: const [
                Text("100", style: TextStyle(fontSize: 10)),
                Text("75", style: TextStyle(fontSize: 10)),
                Text("50", style: TextStyle(fontSize: 10)),
                Text("25", style: TextStyle(fontSize: 10)),
                Text("0", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _LiquidPainter extends CustomPainter {_LiquidPainter({
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


/*
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/helpers/app_colors_helper.dart';
import 'dart:math' as math;

class TankLevelWidget extends StatefulWidget {
  final double level;
  final String svgAsset;
  final String gasType;
  final double minLevel;
  final double maxLevel;

  const TankLevelWidget({
    super.key,
    required this.level,
    required this.svgAsset,
    required this.gasType,
    required this.minLevel,
    required this.maxLevel,
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

    // --------------------------------------------------------
    // SCALE INSET CALCULATION
    // The scale labels always read 0/25/50/75/100 (unchanged).
    // Only the top/bottom insets of the scale block move, so
    // that "100" lands at maxLevel's true position and "0"
    // lands at minLevel's true position on the tank's real
    // 0-100 fill scale. spaceBetween then naturally interpolates
    // 75/50/25 in between. The gas fill itself always uses the
    // raw 0-100 `level` value and is unaffected by this.
    // --------------------------------------------------------
    const baseScaleTop = 15.0;
    const baseScaleBottom = 30.0;
    const scaleAvailableHeight = tankHeight - baseScaleTop - baseScaleBottom; // 155

    final clampedMax = widget.maxLevel.clamp(0, 100).toDouble();
    final clampedMin = widget.minLevel.clamp(0, 100).toDouble();

    final scaleTop =
        baseScaleTop + (100 - clampedMax) / 100 * scaleAvailableHeight;
    final scaleBottom =
        baseScaleBottom + clampedMin / 100 * scaleAvailableHeight;

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
          // top/bottom now come from scaleTop/scaleBottom
          // (computed above from widget.minLevel/widget.maxLevel)
          // instead of the hardcoded 15/30.
          //--------------------------------------------------
          Positioned(
            left: 72,
            top: scaleTop,
            bottom: scaleBottom,
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
}*/
