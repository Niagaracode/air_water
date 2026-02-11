import 'package:air_water/features/reports/view/report_middle.dart';
import 'package:air_water/features/reports/view/report_narrow.dart';
import 'package:air_water/features/reports/view/report_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class ReportLayout extends PageLayoutBuilder {
  const ReportLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const ReportNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const ReportMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const ReportWide();
}