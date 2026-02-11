import 'package:air_water/features/dashboard/presentation/view/dashboard_middle.dart';
import 'package:air_water/features/dashboard/presentation/view/dashboard_narrow.dart';
import 'package:air_water/features/dashboard/presentation/view/dashboard_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class DashboardLayout extends PageLayoutBuilder {
  const DashboardLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const DashboardNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const DashboardMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const DashboardWide();
}