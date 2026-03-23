import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/asset_summary_provider.dart';
import 'asset_summary_pro_table.dart';
import 'asset_summary_filter_bar.dart';

class AssetSummaryContent extends ConsumerStatefulWidget {
  const AssetSummaryContent({super.key});

  @override
  ConsumerState<AssetSummaryContent> createState() => _AssetSummaryContentState();
}

class _AssetSummaryContentState extends ConsumerState<AssetSummaryContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(assetSummaryProvider.notifier).loadData(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
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
                _buildActionButton(Icons.star_outline, 'Add Favourite', () {}),
                const SizedBox(width: 12),
                _buildActionButton(Icons.refresh, 'Refresh', () {
                  ref.read(assetSummaryProvider.notifier).loadData(refresh: true);
                }),
                const SizedBox(width: 12),
                _buildActionButton(Icons.download_outlined, 'Download', () {}),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
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
        const AssetSummaryProTable(),
      ],
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
