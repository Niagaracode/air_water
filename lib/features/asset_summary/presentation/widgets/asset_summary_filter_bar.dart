import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/asset_summary_provider.dart';

class AssetSummaryFilterBar extends ConsumerStatefulWidget {
  const AssetSummaryFilterBar({super.key});

  @override
  ConsumerState<AssetSummaryFilterBar> createState() => _AssetSummaryFilterBarState();
}

class _AssetSummaryFilterBarState extends ConsumerState<AssetSummaryFilterBar> {
  final TextEditingController _plantController = TextEditingController();
  final TextEditingController _tankController = TextEditingController();
  String? _selectedImportance;
  bool _isExpanded = false;

  @override
  void dispose() {
    _plantController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(assetSummaryProvider.notifier).setFilters(
      plant: _plantController.text.isEmpty ? null : _plantController.text,
      tank: _tankController.text.isEmpty ? null : _tankController.text,
      importance: _selectedImportance,
    );
  }

  void _clearFilters() {
    _plantController.clear();
    _tankController.clear();
    setState(() => _selectedImportance = null);
    ref.read(assetSummaryProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(_isExpanded ? Icons.filter_list_off : Icons.filter_list, size: 18),
              label: Text(
                _isExpanded ? 'HIDE FILTERS' : 'SHOW FILTERS (${_activeFilterCount()})',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF374151),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_activeFilterCount() > 0) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ],
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 250,
                  child: _buildTextField(
                    label: 'Plant Name',
                    controller: _plantController,
                    hint: 'Filter by plant...',
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: _buildTextField(
                    label: 'Tank Number',
                    controller: _tankController,
                    hint: 'Filter by tank...',
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: _buildDropdownField(
                    label: 'Importance',
                    value: _selectedImportance,
                    items: const ['High', 'Medium', 'Low'],
                    onChanged: (val) {
                      setState(() => _selectedImportance = val);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  int _activeFilterCount() {
    int count = 0;
    if (_plantController.text.isNotEmpty) count++;
    if (_tankController.text.isNotEmpty) count++;
    if (_selectedImportance != null) count++;
    return count;
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF141E7A), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Select Status', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
              onChanged: onChanged,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
