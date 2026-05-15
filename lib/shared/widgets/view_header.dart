import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onPressed;
  final IconData buttonIcon;
  final Color buttonColor;
  final bool showButton;

  const ViewHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onPressed,
    this.buttonIcon = Icons.add,
    this.buttonColor = const Color(0xFF141E7A),
    this.showButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 16,
        top: 16,
        right: 16,
        bottom: 16,
      ),
      margin: const EdgeInsets.only(
        left: 26,
        right: 26,
        top: 26,
        bottom: 8,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          /// LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.black38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// RIGHT BUTTON
          if (showButton && onPressed != null && buttonText != null)
            ElevatedButton.icon(
              onPressed: onPressed!,

              icon: Icon(
                buttonIcon,
                color: Colors.white,
                size: 18,
              ),

              label: Text(
                buttonText!.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}