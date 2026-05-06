import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceListHeader extends StatelessWidget {
  const DeviceListHeader({
    super.key,
    this.title = 'Device List',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}