import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SummaryCardType {
  primary,
  success,
  warning,
  danger,
  info,
}

class DashboardSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final SummaryCardType type;
  final String? subtitle;

  const DashboardSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.type = SummaryCardType.primary,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colors.icon,
                  size: 24,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  _CardColors _getColors() {
    switch (type) {
      case SummaryCardType.success:
        return _CardColors(
          bg: const Color(0xFFF0FDF4),
          icon: const Color(0xFF16A34A),
          border: const Color(0xFFDCFCE7),
        );
      case SummaryCardType.warning:
        return _CardColors(
          bg: const Color(0xFFFFFBEB),
          icon: const Color(0xFFD97706),
          border: const Color(0xFFFEF3C7),
        );
      case SummaryCardType.danger:
        return _CardColors(
          bg: const Color(0xFFFEF2F2),
          icon: const Color(0xFFDC2626),
          border: const Color(0xFFFEE2E2),
        );
      case SummaryCardType.info:
        return _CardColors(
          bg: const Color(0xFFEFF6FF),
          icon: const Color(0xFF2563EB),
          border: const Color(0xFFDBEAFE),
        );
      case SummaryCardType.primary:
        return _CardColors(
          bg: const Color(0xFFF8FAFC),
          icon: const Color(0xFF141E7A),
          border: const Color(0xFFE2E8F0),
        );
    }
  }
}

class _CardColors {
  final Color bg;
  final Color icon;
  final Color border;

  _CardColors({
    required this.bg,
    required this.icon,
    required this.border,
  });
}
