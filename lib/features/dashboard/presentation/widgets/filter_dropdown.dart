import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.icon = Icons.keyboard_arrow_down,
    this.isExpanded = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.borderRadius = 12,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.textStyle,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final IconData icon;
  final bool isExpanded;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: isExpanded,
          hint: hint != null
              ? Text(
            hint!,
            style: textStyle ?? GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500),
          )
              : null,
          icon: Icon(icon, size: 20, color: Colors.grey.shade600),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item.toString(),
                style: textStyle ?? GoogleFonts.outfit(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}