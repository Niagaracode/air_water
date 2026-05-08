import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TableDataCell extends StatelessWidget {
  const TableDataCell({
    super.key,
    required this.label,
    this.maxLines = 1,
    this.color,
    this.fontSize,
    this.bold = false,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.letterSpacing,
  });

  final String label;
  final int? maxLines;
  final Color? color;
  final double? fontSize;
  final bool bold;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      textAlign: textAlign ?? TextAlign.start,
      style: GoogleFonts.inter(
        fontSize: fontSize ?? 14,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: color ?? (bold ? const Color(0xFF111827) : const Color(0xFF374151)),
      ),
    );
  }
}