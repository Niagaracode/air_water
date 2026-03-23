import 'package:flutter/material.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/asset_summary_narrow.dart';
import 'presentation/view/asset_summary_middle.dart';
import 'presentation/view/asset_summary_wide.dart';

class AssetSummaryLayout extends PageLayoutBuilder {
  const AssetSummaryLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const AssetSummaryNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const AssetSummaryMiddle();

  @override
  Widget buildWide(BuildContext context) => const AssetSummaryWide();
}
