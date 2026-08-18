import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme/app_theme.dart';

class NaveMenu extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const NaveMenu({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: isExpanded ? 6 : 10,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: isSelected ? primary.withValues(alpha: 0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        hoverColor: Colors.black.withValues(alpha: 0.05),
        splashColor: Colors.black.withValues(alpha: 0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: isExpanded ? 12 : 0,
          ),
          child: Row(
            mainAxisAlignment:
            isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              /// ICON
              Icon(icon, size: 20,
                color: isSelected ? Colors.white : iconColor,
              ),

              /// SPACE — animate instead of jump
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isExpanded ? 10 : 0,
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
                        fontSize: 15.5,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.78),
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