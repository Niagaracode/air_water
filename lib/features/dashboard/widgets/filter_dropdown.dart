import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.borderColor,
    this.borderRadius = 8,
    this.label,
    this.backgroundColor,
    this.height = 42,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Color? borderColor;
  final double borderRadius;
  final String? label;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF64748B),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                label != null && item.toString() == value.toString()
                    ? '$label: $item'
                    : item.toString(),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1E293B),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}