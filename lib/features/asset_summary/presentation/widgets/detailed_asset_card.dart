import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/asset_summary_model.dart';
import 'dashboard_tank_visual.dart';

class DetailedAssetCard extends StatelessWidget {
  final AssetSummaryGroup group;

  const DetailedAssetCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // Standardize readings into a map for easy slot access
    final readingsMap = {for (var r in group.readings) r.item.toLowerCase(): r};

    // Extract level for the tank visual (assuming % or decimal string like "40.00 %")
    double levelPerc = 0.0;
    final levelReading = readingsMap['level'];
    if (levelReading != null) {
      final valStr = levelReading.readingValue.replaceAll('%', '').trim();
      levelPerc = (double.tryParse(valStr) ?? 0.0) / 100.0;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Header Bar
          _buildTopBar(),
          
          // Connection Warning (MQTT mocked status)
          _buildStatusWarning(),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Tank Visual
                Expanded(
                  flex: 3,
                  child: Center(
                    child: DashboardTankVisual(levelPercentage: levelPerc),
                  ),
                ),
                
                const SizedBox(width: 24),

                // Right: Data Grid
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildDataRow([
                        _buildDataSlot('Gas', readingsMap['gas']?.readingValue ?? '--'),
                        _buildDataSlot('Pressure', readingsMap['pressure']?.readingValue ?? '--'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDataRow([
                        _buildDataSlot('Level', readingsMap['level']?.readingValue ?? '--'),
                        _buildDataSlot('KL', readingsMap['kl']?.readingValue ?? '--'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDataRow([
                        _buildDataSlot('Cubic Meter', readingsMap['cubic meter']?.readingValue ?? '--'),
                        _buildDataSlot('Ton', readingsMap['ton']?.readingValue ?? '--'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDataRow([
                        _buildDataSlot('Battery Volt', readingsMap['battery volt']?.readingValue ?? '--'),
                        _buildDataSlot('Solar Volt', readingsMap['solar volt']?.readingValue ?? '--'),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A), // App Primary Navy
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.navigation, color: Colors.white, size: 20),
          Text(
            group.deviceId,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.info_outline, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatusWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.red.withOpacity(0.1),
      child: Center(
        child: Text(
          'App cannot communicate with MQTT',
          style: GoogleFonts.inter(
            color: Colors.red,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 16),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildDataSlot(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF141E7A), width: 1),
      ),
      child: Column(
        children: [
          // Slot Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A), // Navy header
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Slot Body
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
