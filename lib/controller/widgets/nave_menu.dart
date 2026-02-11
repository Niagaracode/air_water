import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme/app_theme.dart';

class NaveMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const NaveMenu({
    super.key,
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: isExpanded ? 8 : 0,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? primaryColor
                    : Colors.grey[600],
              ),

              if (isExpanded) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isSelected
                        ? primaryColor
                        : Colors.grey[800],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}