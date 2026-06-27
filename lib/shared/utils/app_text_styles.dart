import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle title({
    Color color = const Color(0xFF111827),
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle body({
    Color color = const Color(0xFF111827),
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle caption({
    Color color = Colors.grey,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}