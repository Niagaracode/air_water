import 'package:flutter/cupertino.dart';
import '../../../core/responsive/page_layout_builder.dart';
import 'others_dashboard_middle.dart';
import 'others_dashboard_narrow.dart';
import 'others_dashboard_wide.dart';

class OthersDashboardLayout extends PageLayoutBuilder {
  const OthersDashboardLayout({
    super.key,
  });

  @override
  Widget buildNarrow(BuildContext context) {
    return const OthersDashboardNarrow();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const OthersDashboardMiddle();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const OthersDashboardWide();
  }
}