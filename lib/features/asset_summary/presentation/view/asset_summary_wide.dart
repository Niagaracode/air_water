import 'package:flutter/material.dart';
import '../widgets/asset_summary_content.dart';

class AssetSummaryWide extends StatelessWidget {
  const AssetSummaryWide({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: AssetSummaryContent(),
      ),
    );
  }
}
