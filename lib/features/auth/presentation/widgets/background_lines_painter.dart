import 'package:flutter/material.dart';

class BackgroundLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width * .1, size.height * .2);
    for (var i = 1; i < 20; i++) {
      canvas.drawCircle(center, i * 60, paint);
    }

    final bottom = Offset(size.width * .9, size.height * .8);
    for (var i = 1; i < 15; i++) {
      canvas.drawCircle(bottom, i * 80, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}