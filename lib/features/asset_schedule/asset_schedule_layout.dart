import 'package:flutter/material.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/asset_schedule_wide.dart';
import 'presentation/view/asset_schedule_middle.dart';
import 'presentation/view/asset_schedule_narrow.dart';

class AssetScheduleLayout extends PageLayoutBuilder {
  const AssetScheduleLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const AssetScheduleNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const AssetScheduleMiddle();

  @override
  Widget buildWide(BuildContext context) => const AssetScheduleWide();
}
