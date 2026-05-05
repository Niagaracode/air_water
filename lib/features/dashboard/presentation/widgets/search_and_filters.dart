import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'filter_dropdown.dart';

class SearchAndFilters extends StatefulWidget {
  const SearchAndFilters({
    super.key,
    required this.onSearchChanged,
    required this.onRegionChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
    this.selectedRegion = 'All Regions',
    this.selectedStatus = 'All Status',
    this.regions = const ['All Regions', 'Arizona', 'New Mexico', 'Texas', 'Oklahoma'],
    this.statuses = const ['All Status', 'Active', 'Warning', 'Critical', 'Offline', 'Out of Order'],
    this.searchHint = 'Search devices...',
  });

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRegionChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onClearFilters;
  final String selectedRegion;
  final String selectedStatus;
  final List<String> regions;
  final List<String> statuses;
  final String searchHint;

  @override
  State<SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<SearchAndFilters> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Region Filter
        Expanded(
          child: FilterDropdown<String>(
            borderColor: Colors.grey.shade300,
            value: widget.selectedRegion,
            items: widget.regions,
            onChanged: (value) {
              if (value != null) {
                widget.onRegionChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        // Status Filter
        Expanded(
          child: FilterDropdown<String>(
            borderColor: Colors.grey.shade300,
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
        // Clear Filters Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E7A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF141E7A)),
            tooltip: 'Clear all filters',
            onPressed: () {
              _searchController.clear();
              widget.onClearFilters();
            },
          ),
        ),
      ],
    );
  }
}