import 'package:flutter/material.dart';
import 'presentation/view/asset_group_wide.dart';
import '../../core/responsive/page_layout_builder.dart';

class AssetGroupLayout extends PageLayoutBuilder {
  const AssetGroupLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const AssetGroupWide();

  @override
  Widget buildMiddle(BuildContext context) => const AssetGroupWide();

  @override
  Widget buildWide(BuildContext context) => const AssetGroupWide();
}
