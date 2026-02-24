import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppClearButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AppClearButton({
    super.key,
    required this.onPressed,
    this.label = 'CLEAR',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style:
          TextButton.styleFrom(
            foregroundColor: const Color(0xFFB91C1C),
            backgroundColor: const Color(0xFFFEF2F2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(const Color(0xFFFEE2E2)),
          ),
      icon: const Icon(
        Icons.restart_alt_rounded,
        size: 18,
        color: Color(0xFFB91C1C),
      ),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
