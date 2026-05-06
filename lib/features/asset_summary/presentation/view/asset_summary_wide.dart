import 'package:flutter/material.dart';
import '../widgets/asset_summary_content.dart';

class AssetSummaryWide extends StatelessWidget {
  const AssetSummaryWide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.1),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: AssetSummaryContent(),
      ),
    );
  }
}
