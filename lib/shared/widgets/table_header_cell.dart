import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TableHeaderCell extends StatelessWidget {
  const TableHeaderCell({super.key, required this.label});
  final String  label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.90),
        letterSpacing: 0.8,
      ),
    );
  }
}