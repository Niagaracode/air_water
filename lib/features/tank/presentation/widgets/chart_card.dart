import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChartCard extends StatelessWidget {

  const ChartCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level (%)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),

              Row(
                children: [
                  _buildLegendItem(
                    'Level',
                    const Color(0xFF141E7A),
                  ),

                  const SizedBox(width: 16),

                  _buildLegendItem(
                    'Forecast',
                    const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 16,
                right: 16,
              ),
              child: Text('data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      String label,
      Color color,
      ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}