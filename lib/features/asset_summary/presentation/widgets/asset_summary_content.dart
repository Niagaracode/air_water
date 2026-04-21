import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/asset_summary_provider.dart';
import '../model/asset_summary_model.dart';
import '../../../user/presentation/controller/user_provider.dart';

import 'asset_summary_pro_table.dart';

import 'asset_summary_filter_bar.dart';
import 'detailed_asset_card.dart';


class AssetSummaryContent extends ConsumerStatefulWidget {
  const AssetSummaryContent({super.key});

  @override
  ConsumerState<AssetSummaryContent> createState() => _AssetSummaryContentState();
}

class _AssetSummaryContentState extends ConsumerState<AssetSummaryContent> {
  int _selectedGroupIndex = 0;
  bool _isVisualView = true;
  bool _isCustomer = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userState = ref.read(userProvider);
      final roleId = userState.currentUser?.roleId;
      _isCustomer = (roleId == 6);
      
      // Customers start in Table View by default
      if (_isCustomer) {
        setState(() {
          _isVisualView = false;
        });
      }
      
      ref.read(assetSummaryProvider.notifier).loadData(refresh: true);
    });
  }

  void _onGroupTap(int index) {
    setState(() {
      _selectedGroupIndex = index;
      _isVisualView = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSET SUMMARY',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor and manage all your assets in one place.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_isCustomer && _isVisualView) ...[
                   _buildActionButton(
                    Icons.arrow_back,
                    'Back to List',
                    () => setState(() => _isVisualView = false),
                  ),
                  const SizedBox(width: 12),
                ],
                _buildActionButton(
                  _isVisualView ? Icons.table_chart_outlined : Icons.dashboard_outlined,
                  _isVisualView ? 'Table View' : 'Visual View',
                  () => setState(() => _isVisualView = !_isVisualView),
                ),
                const SizedBox(width: 12),
                _buildActionButton(Icons.refresh, 'Refresh', () {
                  ref
                      .read(assetSummaryProvider.notifier)
                      .loadData(refresh: true);
                }),
                const SizedBox(width: 12),
                _buildActionButton(Icons.download_outlined, 'Download', () {}),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Tank Selection Tabs (Horizontal Scroll) - Only shown in Visual View
        if (_isVisualView && state.groups.isNotEmpty) ...[
          _buildTankSelector(state.groups),
          const SizedBox(height: 24),
        ],

        if (_isVisualView) ...[
          if (state.isLoading && state.groups.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (state.groups.isEmpty)
            const Center(child: Text('No assets found.'))
          else
            DetailedAssetCard(
              group: state.groups[_selectedGroupIndex.clamp(0, state.groups.length - 1)],
            ),
        ] else ...[
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          const AssetSummaryFilterBar(),
          const SizedBox(height: 24),
          AssetSummaryProTable(
            onGroupTap: _onGroupTap,
          ),
        ],
      ],
    );
  }


  Widget _buildTankSelector(List<AssetSummaryGroup> groups) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(groups.length, (index) {
          final isSelected = _selectedGroupIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedGroupIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF141E7A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF141E7A) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  '${groups[index].plantName} ${groups[index].tankNumber}',
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label.toUpperCase(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
