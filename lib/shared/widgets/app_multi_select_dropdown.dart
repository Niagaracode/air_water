import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppMultiSelectDropdown<T> extends StatefulWidget {
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
  State<AppMultiSelectDropdown<T>> createState() => _AppMultiSelectDropdownState<T>();
}

class _AppMultiSelectDropdownState<T> extends State<AppMultiSelectDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 5),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                width: size.width,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    final allSelected = widget.selectedItems.length == widget.items.length && widget.items.isNotEmpty;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.items.isNotEmpty)
                          CheckboxListTile(
                            title: Text('Select All', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                            value: allSelected,
                            onChanged: (bool? value) {
                              setOverlayState(() {
                                if (value == true) {
                                  widget.onChanged(List<T>.from(widget.items));
                                } else {
                                  widget.onChanged([]);
                                }
                              });
                            },
                            activeColor: const Color(0xFF141E7A),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              final isSelected = widget.selectedItems.contains(item);
                              return CheckboxListTile(
                                title: Text(widget.itemLabel(item), style: GoogleFonts.inter(fontSize: 14)),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setOverlayState(() {
                                    final newList = List<T>.from(widget.selectedItems);
                                    if (value == true) {
                                      newList.add(item);
                                    } else {
                                      newList.remove(item);
                                    }
                                    widget.onChanged(newList);
                                  });
                                },
                                activeColor: const Color(0xFF141E7A),
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _closeDropdown,
                                child: Text(
                                  'DONE',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF141E7A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isOpen ? const Color(0xFF141E7A) : const Color(0xFFE5E7EB), width: _isOpen ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: widget.selectedItems.isEmpty
                        ? Text(
                            widget.hint,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: widget.selectedItems.map((item) {
                              return Chip(
                                label: Text(
                                  widget.itemLabel(item),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF141E7A),
                                  ),
                                ),
                                backgroundColor: const Color(0xFFEFF6FF),
                                deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF141E7A)),
                                onDeleted: () {
                                  final newList = List<T>.from(widget.selectedItems)..remove(item);
                                  widget.onChanged(newList);
                                },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: _isOpen ? const Color(0xFF141E7A) : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
