import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceListHeader extends StatelessWidget {
  const DeviceListHeader({
    super.key,
    this.title = 'Device List',
    this.onActionTap,
    this.actionIcon = Icons.more_horiz,
    this.showAction = false,
    this.subtitle,
  });

  final String title;
  final VoidCallback? onActionTap;
  final IconData actionIcon;
  final bool showAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        if (showAction)
          IconButton(
            onPressed: onActionTap,
            icon: Icon(actionIcon),
            tooltip: 'More options',
          ),
      ],
    );
  }
}