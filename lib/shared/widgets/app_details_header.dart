import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDetailsHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<BreadcrumbItem> breadcrumbs;
  final VoidCallback onBack;

  const AppDetailsHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.breadcrumbs,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {

    final canPop = Navigator.canPop(context);

    return Row(
      children: [
        if(canPop)...[
          Tooltip(
            message: 'Back',
            child: InkWell(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: _buildBreadcrumbs(),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBreadcrumbs() {
    final List<Widget> items = [];
    for (int i = 0; i < breadcrumbs.length; i++) {
      final b = breadcrumbs[i];
      items.add(
        GestureDetector(
          onTap: b.onTap,
          child: Text(
            b.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: b.isCurrent ? const Color(0xFF141E7A) : const Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      if (i < breadcrumbs.length - 1) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right, size: 14, color: Color(0xFF9CA3AF)),
          ),
        );
      }
    }
    return items;
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  final bool isCurrent;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
    this.isCurrent = false,
  });
}
