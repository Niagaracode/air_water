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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        hoverColor: primaryColor.withOpacity(0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isExpanded ? 12 : 0,
          ),
          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [

              /// ICON
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? primaryColor
                    : Colors.grey.shade600,
              ),

              /// SPACE — animate instead of jump
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isExpanded ? 14 : 0,
              ),

              /// LABEL — smooth fade/size animation
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.centerLeft,
                  widthFactor: isExpanded ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isExpanded ? 1 : 0,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}