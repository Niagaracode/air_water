import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final Widget? Function(BuildContext context, T item)? itemTrailingBuilder;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.itemLabel,
    this.onChanged,
    this.enabled = true,
    this.itemTrailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              color: enabled ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB),
              fontSize: 14,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
            size: 20,
          ),
          onChanged: enabled ? onChanged : null,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          selectedItemBuilder: itemTrailingBuilder != null
              ? (BuildContext context) {
                  return items.map((T item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        itemLabel(item),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                }
              : null,
          items: items.map((T item) {
            final trailing = itemTrailingBuilder?.call(context, item);
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      itemLabel(item),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            );
          }).toList(),
          isExpanded: true,
        ),
      ),
    );
  }
}
