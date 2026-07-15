import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import '../../../core/app_theme/app_theme.dart';
import '../provider/dashboard_provider.dart';
import 'filter_dropdown.dart';

class SearchAndFilters extends ConsumerStatefulWidget {
  const SearchAndFilters({
    super.key,
    required this.isNarrow,
    required this.onSearchChanged,
    required this.onRegionChanged,
    required this.onStatusChanged,
    required this.onProductChanged,
    required this.onClearFilters,
    this.selectedRegion = 'All Regions',
    this.selectedStatus = 'All Status',
    this.selectedProduct = 'All Product',
    this.statuses = const [
      'All Status',
      'Online',
      'Offline',
      'Low Level',
      'Critical',
      'Reorder',
    ],

    this.products = const ['All Product', 'LOX', 'LIN', 'LAR', 'LMO', 'LCO₂'],
    this.searchHint = 'Search devices...',
    this.showStats = true,
  });

  final bool isNarrow;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onProductChanged;
  final VoidCallback onClearFilters;
  final String selectedRegion;
  final String selectedStatus;
  final List<String> statuses;
  final String selectedProduct;
  final List<String> products;
  final String searchHint;
  final bool showStats;


  @override
  ConsumerState<SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends ConsumerState<SearchAndFilters> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  late final Debouncer _debouncer;
  int _resultCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Setup debouncer for search
    _debouncer = Debouncer(
      const Duration(milliseconds: 500),
      initialValue: '',
      checkEquality: true,
    );

    // Listen to search changes with debounce
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debouncer.setValue(_searchController.text);
    _debouncer.values.listen((searchTerm) {
      if (mounted && searchTerm != null) {
        widget.onSearchChanged(searchTerm);
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    widget.onClearFilters();
    setState(() {
      _resultCount = 0;
    });
  }

  void updateResultCount(int count) {
    if (mounted) {
      setState(() {
        _resultCount = count;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionProvider);

    final hasFilters =
        widget.selectedRegion != 'All Regions' ||
        widget.selectedStatus != 'All Status' ||
        widget.selectedProduct != 'All Product' ||
        _searchController.text.isNotEmpty;

    if(widget.isNarrow) {
      return Column(
        children: [

          Row(
            children: [
              /// Search Bar with improved styling
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: (value) {
                      // Debouncer handles this
                    },
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: _clearFilters,
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              /// Product Filter (NEW)
              Expanded(
                child: FilterDropdown<String>(
                  borderColor: const Color(0xFFE2E8F0),
                  borderRadius: 12,
                  label: 'Product',
                  value: widget.selectedProduct,
                  items: widget.products,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onProductChanged(value);
                    }
                  },
                ),
              ),

            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [


              /// Product Filter (NEW)
              Expanded(
                child: FilterDropdown<String>(
                  borderColor: const Color(0xFFE2E8F0),
                  borderRadius: 12,
                  label: 'Product',
                  value: widget.selectedProduct,
                  items: widget.products,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onProductChanged(value);
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),

              /// Region Filter
              Expanded(
                child: regionsAsync.when(
                  data: (regions) {
                    return FilterDropdown<String>(
                      borderColor: const Color(0xFFE2E8F0),
                      borderRadius: 12,
                      label: 'Region',
                      value: widget.selectedRegion,
                      items: regions,
                      onChanged: (value) {
                        if (value != null) {
                          widget.onRegionChanged(value);
                        }
                      },
                    );
                  },
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => FilterDropdown<String>(
                    borderColor: const Color(0xFFE2E8F0),
                    borderRadius: 12,
                    label: 'Region',
                    value: 'All Regions',
                    items: const ['All Regions'],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onRegionChanged(value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// Status Filter
              Expanded(
                child: FilterDropdown<String>(
                  borderColor: const Color(0xFFE2E8F0),
                  borderRadius: 12,
                  label: 'Status',
                  value: widget.selectedStatus,
                  items: widget.statuses,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onStatusChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),

              /// Clear Filters Button
              Container(
                decoration: BoxDecoration(
                  color: hasFilters
                      ? primary.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFilters
                        ? primary.withValues(alpha: 0.3)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_alt_off,
                    color: hasFilters
                        ? primary
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  tooltip: 'Clear all filters',
                  onPressed: hasFilters ? _clearFilters : null,
                ),
              ),
            ],
          ),

          /// Search Stats & Active Filters (Optional)
          if (widget.showStats && hasFilters)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  /// Search results count
                  if (_searchController.text.isNotEmpty && _resultCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_resultCount result${_resultCount != 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: primary,
                        ),
                      ),
                    ),

                  if (_searchController.text.isNotEmpty && _resultCount > 0)
                    const SizedBox(width: 8),

                  /// Active filter chips
                  if (widget.selectedRegion != 'All Regions')
                    _buildFilterChip(
                      label: 'Region: ${widget.selectedRegion}',
                      onRemove: () => widget.onRegionChanged('All Regions'),
                    ),

                  if (widget.selectedStatus != 'All Status')
                    _buildFilterChip(
                      label: 'Status: ${widget.selectedStatus}',
                      onRemove: () => widget.onStatusChanged('All Status'),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            /// Search Bar with improved styling
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    // Debouncer handles this
                  },
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: _clearFilters,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// Product Filter (NEW)
            Expanded(
              child: FilterDropdown<String>(
                borderColor: const Color(0xFFE2E8F0),
                borderRadius: 12,
                label: 'Product',
                value: widget.selectedProduct,
                items: widget.products,
                onChanged: (value) {
                  if (value != null) {
                    widget.onProductChanged(value);
                  }
                },
              ),
            ),

            const SizedBox(width: 12),

            /// Region Filter
            Expanded(
              child: regionsAsync.when(
                data: (regions) {
                  return FilterDropdown<String>(
                    borderColor: const Color(0xFFE2E8F0),
                    borderRadius: 12,
                    label: 'Region',
                    value: widget.selectedRegion,
                    items: regions,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onRegionChanged(value);
                      }
                    },
                  );
                },
                loading: () => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => FilterDropdown<String>(
                  borderColor: const Color(0xFFE2E8F0),
                  borderRadius: 12,
                  label: 'Region',
                  value: 'All Regions',
                  items: const ['All Regions'],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onRegionChanged(value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// Status Filter
            Expanded(
              child: FilterDropdown<String>(
                borderColor: const Color(0xFFE2E8F0),
                borderRadius: 12,
                label: 'Status',
                value: widget.selectedStatus,
                items: widget.statuses,
                onChanged: (value) {
                  if (value != null) {
                    widget.onStatusChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            /// Clear Filters Button
            Container(
              decoration: BoxDecoration(
                color: hasFilters
                    ? primary.withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFilters
                      ? primary.withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.filter_alt_off,
                  color: hasFilters
                      ? primary
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
                tooltip: 'Clear all filters',
                onPressed: hasFilters ? _clearFilters : null,
              ),
            ),
          ],
        ),

        /// Search Stats & Active Filters (Optional)
        if (widget.showStats && hasFilters)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                /// Search results count
                if (_searchController.text.isNotEmpty && _resultCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_resultCount result${_resultCount != 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primary,
                      ),
                    ),
                  ),

                if (_searchController.text.isNotEmpty && _resultCount > 0)
                  const SizedBox(width: 8),

                /// Active filter chips
                if (widget.selectedRegion != 'All Regions')
                  _buildFilterChip(
                    label: 'Region: ${widget.selectedRegion}',
                    onRemove: () => widget.onRegionChanged('All Regions'),
                  ),

                if (widget.selectedStatus != 'All Status')
                  _buildFilterChip(
                    label: 'Status: ${widget.selectedStatus}',
                    onRemove: () => widget.onStatusChanged('All Status'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(4),
            child: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
