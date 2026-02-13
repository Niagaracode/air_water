import 'package:flutter/material.dart';

class SearchableDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final String title;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const SearchableDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.title,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final _searchController = TextEditingController();
  List<String> _filteredItems = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(SearchableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
      if (_isOpen) {
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _searchController.clear();
    _filteredItems = widget.items;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier to close dropdown when tapping outside
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Dropdown overlay
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with title and close button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _closeDropdown,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          // Search field
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search ${widget.title}',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1B1B4B),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              onChanged: (query) {
                                setOverlayState(() {
                                  _filteredItems = widget.items
                                      .where(
                                        (item) => item.toLowerCase().contains(
                                              query.toLowerCase(),
                                            ),
                                      )
                                      .toList();
                                });
                              },
                            ),
                          ),
                          // Items list
                          Flexible(
                            child: _filteredItems.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No results found',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final isSelected = item == widget.value;
                                      return InkWell(
                                        onTap: () {
                                          widget.onChanged(item);
                                          _closeDropdown();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          color: isSelected
                                              ? const Color(0xFFF0F0FF)
                                              : null,
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.clear();
    setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isOpen
                  ? const Color(0xFF1B1B4B)
                  : Colors.grey.shade300,
            ),
            color: widget.enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.value ?? widget.hint,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.value != null
                        ? Colors.black
                        : Colors.grey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
