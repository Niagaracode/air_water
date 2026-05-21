import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class TankMapTab extends ConsumerWidget {

  const TankMapTab({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(24),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 72,
              color: Color(0xFF9CA3AF),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Map integration pending',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}