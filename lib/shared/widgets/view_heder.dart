import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewHeder extends StatelessWidget {
  const ViewHeder({super.key, required this.title, required this.subTitle});
  final String  title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      margin: const EdgeInsets.only(left: 26, right: 26, top: 26, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subTitle,
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => {},
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'CREATE TEMPLATE',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}