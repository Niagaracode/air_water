import 'package:flutter/material.dart';
import 'dart:math' as Math;

class DashboardTankVisual extends StatelessWidget {
  final double levelPercentage; // 0.0 to 1.0
  final double width;
  final double height;

  const DashboardTankVisual({
    super.key,
    required this.levelPercentage,
    this.width = 180,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _TankVisualPainter(levelPercentage: levelPercentage),
          ),
          Positioned(
            top: height * 0.45,
            child: Text(
              '${(levelPercentage * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TankVisualPainter extends CustomPainter {
  final double levelPercentage;

  _TankVisualPainter({required this.levelPercentage});

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 40;
    final double tankW = size.width * 0.45;
    final double tankH = size.height - (padding * 2);
    final double cornerR = tankW * 0.4;
    
    final x = (size.width - tankW) / 2;
    final y = padding;

    final tankRect = RRect.fromLTRBR(x, y, x + tankW, y + tankH, Radius.circular(cornerR));

    // Draw Background (Empty Tank Color)
    final bgPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tankRect, bgPaint);

    // Draw Leg/Support structures (Stylized from screenshot)
    final supportPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final legW = 10.0;
    final legH = 40.0;
    
    // Left Support
    canvas.drawRect(Rect.fromLTWH(x - 5, y + tankH - 20, legW, legH), supportPaint);
    // Right Support
    canvas.drawRect(Rect.fromLTWH(x + tankW - 5, y + tankH - 20, legW, legH), supportPaint);
    // Bottom drain piping stub
    canvas.drawRect(Rect.fromLTWH(x + tankW / 2 - 5, y + tankH, 10, 15), supportPaint);

    // Draw Fill Level
    if (levelPercentage > 0) {
      final fillHeight = tankH * levelPercentage.clamp(0.0, 1.0);
      final fillRect = Rect.fromLTWH(x, y + tankH - fillHeight, tankW, fillHeight);
      
      final fillPaint = Paint()
        ..color = const Color(0xFF22C55E) // Green level
        ..style = PaintingStyle.fill;

      // Clip the green fill to the tank rounded shape
      canvas.save();
      canvas.clipRRect(tankRect);
      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }

    // Draw Outline
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(tankRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
