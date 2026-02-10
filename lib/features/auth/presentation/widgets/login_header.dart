import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'background_lines_painter.dart';

class LoginHeader extends StatelessWidget {
  final bool isNarrow;

  const LoginHeader({super.key, required this.isNarrow});

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Container(
          height: isNarrow ? MediaQuery.of(context).size.height * 0.35:
          MediaQuery.of(context).size.height,
          width: double.infinity,
          color: Theme.of(context).primaryColor,
          child: CustomPaint(painter: BackgroundLinesPainter()),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/png/app_logo.png',
                height: isNarrow ? 120 : 180,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ],
    );
  }
}