import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildEmptyTanksView() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.devices_other,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No Tanks Available',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You don\'t have any tanks assigned yet',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  );
}

Widget buildEmptyDetailView() {
  return Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Tank Selected',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a tank from the left panel to view details',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}