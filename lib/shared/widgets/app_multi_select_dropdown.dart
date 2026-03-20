import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppMultiSelectDropdown<T> extends StatelessWidget {
  final List<T> selectedItems;
  final List<T> items;
  final String hint;
  final String Function(T) itemLabel;
  final ValueChanged<List<T>> onChanged;
  final bool enabled;

  const AppMultiSelectDropdown({
    super.key,
    required this.selectedItems,
    required this.items,
    required this.hint,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: GestureDetector(
              onTap: () => _showMultiSelectDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: selectedItems.isEmpty
                          ? Text(
                              hint,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: selectedItems.map((item) {
                                return Chip(
                                  label: Text(
                                    itemLabel(item),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF141E7A),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF141E7A)),
                                  onDeleted: () {
                                    final newList = List<T>.from(selectedItems)..remove(item);
                                    onChanged(newList);
                                  },
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMultiSelectDialog(BuildContext context) {
    List<T> tempSelectedItems = List<T>.from(selectedItems);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Items', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = tempSelectedItems.contains(item);
                    return CheckboxListTile(
                      title: Text(itemLabel(item), style: GoogleFonts.inter(fontSize: 14)),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedItems.add(item);
                          } else {
                            tempSelectedItems.remove(item);
                          }
                        });
                        // Pass to parent immediately so background chips update too
                        onChanged(tempSelectedItems);
                      },
                      activeColor: const Color(0xFF141E7A),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF141E7A),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
