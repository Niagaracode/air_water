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

  // Local copy of selected items used inside the overlay to avoid duplicates
  late List<T> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List<T>.from(widget.selectedItems);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    // Sync local selection with current parent state every time we open
    _localSelected = List<T>.from(widget.selectedItems);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    // Commit local selection to parent on close
    widget.onChanged(_localSelected);
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
                    // Use _localSelected (local copy) to drive all checked state
                    final allSelected = _localSelected.length ==
                            widget.items.length &&
                        widget.items.isNotEmpty;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.items.isNotEmpty)
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              'Select All',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: allSelected
                                    ? const Color(0xFF141E7A)
                                    : Colors.black87,
                              ),
                            ),
                            selected: allSelected,
                            selectedTileColor: const Color(0xFFEFF6FF),
                            trailing: allSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Color(0xFF141E7A), size: 18)
                                : null,
                            onTap: () {
                              setOverlayState(() {
                                if (!allSelected) {
                                  _localSelected = List<T>.from(widget.items);
                                } else {
                                  _localSelected = [];
                                }
                              });
                            },
                          ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              // Check against local copy — prevents duplicates and
                              // correctly shows prior selection on reopen
                              final isSelected = _localSelected.contains(item);
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  widget.itemLabel(item),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isSelected
                                        ? const Color(0xFF141E7A)
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                selectedTileColor: const Color(0xFFF3F8FF),
                                trailing: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Color(0xFF141E7A), size: 18)
                                    : null,
                                onTap: () {
                                  setOverlayState(() {
                                    if (isSelected) {
                                      _localSelected.remove(item);
                                    } else {
                                      _localSelected.add(item);
                                    }
                                  });
                                },
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
                            children: widget.selectedItems.toSet().map((item) {
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
    // Remove overlay without firing onChanged (widget is being disposed)
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}
