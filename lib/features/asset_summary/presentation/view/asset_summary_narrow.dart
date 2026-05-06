import 'package:flutter/material.dart';
import '../widgets/asset_summary_content.dart';

class AssetSummaryNarrow extends StatelessWidget {
  const AssetSummaryNarrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.1),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: AssetSummaryContent(),
      ),
    );
  }
}
