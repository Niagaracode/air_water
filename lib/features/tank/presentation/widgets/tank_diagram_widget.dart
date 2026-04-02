import 'package:flutter/material.dart';
import 'dart:math' as Math;

class TankDiagramWidget extends StatelessWidget {
  final String tankType;
  final double width;
  final double height;

  const TankDiagramWidget({
    super.key,
    required this.tankType,
    this.width = 300,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomPaint(
        painter: TankPainter(tankType: tankType),
      ),
    );
  }
}

class TankPainter extends CustomPainter {
  final String tankType;

  TankPainter({required this.tankType});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFEF9E7) // Light Cream fill
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF374151) // Charcoal border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dashedPaint = Paint()
      ..color = const Color(0xFF9CA3AF) // Muted grey for guide lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final typeLower = tankType.toLowerCase();

    // Map out each specific type based on user request mapping
    if (typeLower.contains('rectangular')) {
      _drawRectangular3D(canvas, size, fillPaint, borderPaint);
    } else if (typeLower.contains('horizontal with 2:1 ellipsoidal ends') || typeLower.contains('vertical with 2:1 ellipsoidal ends')) {
      _drawRoundedTank(canvas, size, fillPaint, borderPaint, dashedPaint, isHorizontal: typeLower.contains('horizontal'), isEllipsoidal: true);
    } else if (typeLower.contains('horizontal with hemispherical ends') || typeLower.contains('vertical with hemispherical ends')) {
      _drawRoundedTank(canvas, size, fillPaint, borderPaint, dashedPaint, isHorizontal: typeLower.contains('horizontal'), isEllipsoidal: false);
    } else if (typeLower == 'spherical' || typeLower.startsWith('spherical')) {
      _drawSpherical(canvas, size, fillPaint, borderPaint, dashedPaint);
    } else if (typeLower.contains('horizontal with flat ends') || typeLower.contains('vertical with flat ends')) {
      _drawFlatEndsTank(canvas, size, fillPaint, borderPaint, dashedPaint, isHorizontal: typeLower.contains('horizontal'));
    } else if (typeLower.contains('horizontal with variable dished ends') || typeLower.contains('vertical with variable dished ends')) {
      _drawDishedTank(canvas, size, fillPaint, borderPaint, dashedPaint, isHorizontal: typeLower.contains('horizontal'));
    } else if (typeLower.contains('vertical with conical bottom end')) {
      _drawVerticalConical(canvas, size, fillPaint, borderPaint, dashedPaint);
    } else if (typeLower.contains('cylinder') || typeLower.contains('cyclinder') || typeLower.contains('none')) {
      // Default to Cylinder
      _drawFlatEndsTank(canvas, size, fillPaint, borderPaint, dashedPaint, isHorizontal: false);
    } else {
      // Fallback
      _drawFlatEndsTank(canvas, size, fillPaint, borderPaint, dashedPaint, isHorizontal: typeLower.contains('horizontal'));
    }
  }

  void _drawDimension(Canvas canvas, Offset p1, Offset p2, String label, {bool isHorizontal = true, Color color = const Color(0xFFD1D5DB)}) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    final extensionPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.5;

    final tickLen = 5.0;
    
    // Smart Extension line direction (towards typical object centers)
    if (isHorizontal) {
       // If dy is low (top), extend down. If dy is high (bottom), extend up.
       double ext = p1.dy < 150 ? 15 : -15; 
       canvas.drawLine(p1, Offset(p1.dx, p1.dy + ext), extensionPaint);
       canvas.drawLine(p2, Offset(p2.dx, p2.dy + ext), extensionPaint);
    } else {
       // If dx is low (left), extend right. If dx is high (right), extend left.
       double ext = p1.dx < 150 ? 15 : -15; 
       canvas.drawLine(p1, Offset(p1.dx + ext, p1.dy), extensionPaint);
       canvas.drawLine(p2, Offset(p2.dx + ext, p2.dy), extensionPaint);
    }

    // Draw main dimension line
    canvas.drawLine(p1, p2, linePaint);
    // Draw arrows/ticks
    if (isHorizontal) {
       canvas.drawLine(Offset(p1.dx, p1.dy - tickLen), Offset(p1.dx, p1.dy + tickLen), linePaint);
       canvas.drawLine(Offset(p2.dx, p2.dy - tickLen), Offset(p2.dx, p2.dy + tickLen), linePaint);
    } else {
       canvas.drawLine(Offset(p1.dx - tickLen, p1.dy), Offset(p1.dx + tickLen, p1.dy), linePaint);
       canvas.drawLine(Offset(p2.dx - tickLen, p2.dy), Offset(p2.dx + tickLen, p2.dy), linePaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    if (isHorizontal) {
      textPainter.paint(canvas, Offset((p1.dx + p2.dx) / 2 - textPainter.width / 2, p1.dy + 4));
    } else {
      double offsetX = p1.dx < 150 ? -textPainter.width - 10 : 10;
      textPainter.paint(canvas, Offset(p1.dx + offsetX, (p1.dy + p2.dy) / 2 - textPainter.height / 2));
    }
  }

  void _drawRectangular3D(Canvas canvas, Size size, Paint fill, Paint border) {
    double w = size.width * 0.45;
    double h = size.height * 0.45;
    double d = size.width * 0.25;
    double x = (size.width - w - d/2) / 2;
    double y = (size.height - h - d/2) / 2 + d/2;

    Path front = Path()..addRect(Rect.fromLTWH(x, y, w, h));
    Path top = Path()
      ..moveTo(x, y)
      ..lineTo(x + d/2, y - d/2)
      ..lineTo(x + w + d/2, y - d/2)
      ..lineTo(x + w, y)
      ..close();
    Path side = Path()
      ..moveTo(x + w, y)
      ..lineTo(x + w + d/2, y - d/2)
      ..lineTo(x + w + d/2, y + h - d/2)
      ..lineTo(x + w, y + h)
      ..close();

    canvas.drawPath(front, fill);
    canvas.drawPath(top, fill);
    canvas.drawPath(side, fill);
    canvas.drawPath(front, border);
    canvas.drawPath(top, border);
    canvas.drawPath(side, border);

    // Labels W, H, D
    _drawDimension(canvas, Offset(x, y + h + 20), Offset(x + w, y + h + 20), "W");
    _drawDimension(canvas, Offset(x + w + d/2 + 25, y - d/2), Offset(x + w + d/2 + 25, y + h - d/2), "H", isHorizontal: false);
    double dx = x + w + 10;
    double dy = y + h + 5;
    _drawDimension(canvas, Offset(dx, dy), Offset(dx + d / 2, dy - d / 2), "D");
  }

  void _drawRoundedTank(Canvas canvas, Size size, Paint fill, Paint border, Paint dashed, {required bool isHorizontal, required bool isEllipsoidal}) {
    double mainW = isHorizontal ? size.width * 0.55 : size.width * 0.45;
    double mainH = isHorizontal ? size.height * 0.45 : size.height * 0.55;
    double r = isHorizontal ? mainH / 2 : mainW / 2;
    double x = (size.width - mainW) / 2;
    double y = (size.height - mainH) / 2;

    Path path = Path();
    if (isHorizontal) {
       path.moveTo(x, y);
       path.lineTo(x + mainW, y);
       if (!isEllipsoidal) {
          // Hemispherical - Use perfect Arc
          path.arcTo(Rect.fromLTWH(x + mainW - r, y, 2 * r, 2 * r), -1.57, 3.14, false);
       } else {
          // 2:1 Ellipsoidal Approximation (flatter)
          path.cubicTo(x + mainW + r * 0.5, y, x + mainW + r * 0.5, y + mainH, x + mainW, y + mainH);
       }
       path.lineTo(x, y + mainH);
       if (!isEllipsoidal) {
          path.arcTo(Rect.fromLTWH(x - r, y, 2 * r, 2 * r), 1.57, 3.14, false);
       } else {
          path.cubicTo(x - r * 0.5, y + mainH, x - r * 0.5, y, x, y);
       }
       path.close();
    } else {
       path.moveTo(x, y);
       if (!isEllipsoidal) {
          path.arcTo(Rect.fromLTWH(x, y - r, 2 * r, 2 * r), 3.14, 3.14, false);
       } else {
          path.cubicTo(x, y - r * 0.5, x + mainW, y - r * 0.5, x + mainW, y);
       }
       path.lineTo(x + mainW, y + mainH);
       if (!isEllipsoidal) {
          path.arcTo(Rect.fromLTWH(x, y + mainH - r, 2 * r, 2 * r), 0, 3.14, false);
       } else {
          path.cubicTo(x + mainW, y + mainH + r * 0.5, x, y + mainH + r * 0.5, x, y + mainH);
       }
       path.close();
    }

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    // Dashed guide lines
    if (isHorizontal) {
       _drawDashedLine(canvas, Offset(x, y), Offset(x, y + mainH), dashed);
       _drawDashedLine(canvas, Offset(x + mainW, y), Offset(x + mainW, y + mainH), dashed);
    } else {
       _drawDashedLine(canvas, Offset(x, y), Offset(x + mainW, y), dashed);
       _drawDashedLine(canvas, Offset(x, y + mainH), Offset(x + mainW, y + mainH), dashed);
    }

    // Dimensions
    if (isHorizontal) {
       _drawDimension(canvas, Offset(x, y + mainH + 20), Offset(x + mainW, y + mainH + 20), "L");
       double endX = isEllipsoidal ? x - r * 0.5 : x - r;
       _drawDimension(canvas, Offset(endX - 25, y), Offset(endX - 25, y + mainH), "D", isHorizontal: false);
    } else {
       _drawDimension(canvas, Offset(x - 35, y), Offset(x - 35, y + mainH), "L", isHorizontal: false);
       double endY = isEllipsoidal ? y - r * 0.5 : y - r;
       _drawDimension(canvas, Offset(x, endY - 25), Offset(x + mainW, endY - 25), "D");
    }
  }

  void _drawFlatEndsTank(Canvas canvas, Size size, Paint fill, Paint border, Paint dashed, {required bool isHorizontal}) {
    double w = isHorizontal ? size.width * 0.65 : size.width * 0.45;
    double h = isHorizontal ? size.height * 0.45 : size.height * 0.65;
    double x = (size.width - w) / 2;
    double y = (size.height - h) / 2;

    Rect rect = Rect.fromLTWH(x, y, w, h);
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);

    if (isHorizontal) {
       _drawDimension(canvas, Offset(x, y + h + 20), Offset(x + w, y + h + 20), "L");
       _drawDimension(canvas, Offset(x - 25, y), Offset(x - 25, y + h), "D", isHorizontal: false);
    } else {
       _drawDimension(canvas, Offset(x - 25, y), Offset(x - 25, y + h), "L", isHorizontal: false);
       _drawDimension(canvas, Offset(x, y - 25), Offset(x + w, y - 25), "D");
    }
  }

  void _drawDishedTank(Canvas canvas, Size size, Paint fill, Paint border, Paint dashed, {required bool isHorizontal}) {
    double mainW = isHorizontal ? size.width * 0.55 : size.width * 0.45;
    double mainH = isHorizontal ? size.height * 0.45 : size.height * 0.55;
    double dl = isHorizontal ? mainW * 0.20 : mainH * 0.20; // Exact 20% proportion
    double x = (size.width - mainW) / 2;
    double y = (size.height - mainH) / 2;

    Path path = Path();
    if (isHorizontal) {
       path.moveTo(x, y);
       path.lineTo(x + mainW, y);
       path.quadraticBezierTo(x + mainW + dl, y + mainH/2, x + mainW, y + mainH);
       path.lineTo(x, y + mainH);
       path.quadraticBezierTo(x - dl, y + mainH/2, x, y);
       path.close();
    } else {
       path.moveTo(x, y);
       path.quadraticBezierTo(x+mainW/2, y - dl, x + mainW, y);
       path.lineTo(x + mainW, y + mainH);
       path.quadraticBezierTo(x + mainW/2, y + mainH + dl, x, y + mainH);
       path.close();
    }

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    // Dashed guide lines at the body-end junction
    if (isHorizontal) {
       _drawDashedLine(canvas, Offset(x, y), Offset(x, y+mainH), dashed);
       _drawDashedLine(canvas, Offset(x+mainW, y), Offset(x+mainW, y+mainH), dashed);
    } else {
       _drawDashedLine(canvas, Offset(x, y), Offset(x+mainW, y), dashed);
       _drawDashedLine(canvas, Offset(x, y+mainH), Offset(x+mainW, y+mainH), dashed);
    }

    if (isHorizontal) {
       _drawDimension(canvas, Offset(x, y + mainH + 20), Offset(x + mainW, y + mainH + 20), "L");
       _drawDimension(canvas, Offset(x + mainW, y + mainH + 20), Offset(x + mainW + dl, y + mainH + 20), "DL");
       _drawDimension(canvas, Offset(x - dl - 25, y), Offset(x - dl - 25, y + mainH), "D", isHorizontal: false);
    } else {
       // Exact blueprint layout: L and DL on the left, D on top
       _drawDimension(canvas, Offset(x - 35, y), Offset(x - 35, y + mainH), "L", isHorizontal: false);
       _drawDimension(canvas, Offset(x - 35, y + mainH), Offset(x - 35, y + mainH + dl), "DL", isHorizontal: false);
       _drawDimension(canvas, Offset(x, y - dl - 25), Offset(x + mainW, y - dl - 25), "D");
    }
  }

  void _drawVerticalConical(Canvas canvas, Size size, Paint fill, Paint border, Paint dashed) {
    double w = size.width * 0.55;
    double h = size.height * 0.5;
    double cl = size.height * 0.2;
    double x = (size.width - w) / 2;
    double y = (size.height - h - cl) / 2;

    Path path = Path()
      ..moveTo(x, y)
      ..lineTo(x + w, y)
      ..lineTo(x + w, y + h)
      ..lineTo(x + w / 2, y + h + cl)
      ..lineTo(x, y + h)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
    _drawDashedLine(canvas, Offset(x, y + h), Offset(x + w, y + h), dashed);

    _drawDimension(canvas, Offset(x, y - 25), Offset(x + w, y - 25), "D");
    _drawDimension(canvas, Offset(x + w + 25, y), Offset(x + w + 25, y + h), "L", isHorizontal: false);
    _drawDimension(canvas, Offset(x + w + 25, y + h), Offset(x + w + 25, y + h + cl), "CL", isHorizontal: false);
  }

  void _drawSpherical(Canvas canvas, Size size, Paint fill, Paint border, Paint dashed) {
    double r = size.width * 0.35;
    double cx = size.width / 2;
    double cy = size.height / 2;

    canvas.drawCircle(Offset(cx, cy), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, border);
    
    // Diameter D only on the left, matching screenshot
    _drawDimension(canvas, Offset(cx - r - 25, cy - r), Offset(cx - r - 25, cy + r), "D", isHorizontal: false);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dashLen = 5.0;
    final dashGap = 5.0;
    double dx = p2.dx - p1.dx;
    double dy = p2.dy - p1.dy;
    double len = Math.sqrt(dx * dx + dy * dy);
    dx /= len;
    dy /= len;

    double cur = 0;
    while (cur < len) {
       canvas.drawLine(Offset(p1.dx + dx * cur, p1.dy + dy * cur), 
                       Offset(p1.dx + dx * Math.min(cur + dashLen, len), p1.dy + dy * Math.min(cur + dashLen, len)), paint);
       cur += dashLen + dashGap;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
