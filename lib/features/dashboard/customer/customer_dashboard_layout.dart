import 'package:flutter/cupertino.dart';
import '../../../core/responsive/page_layout_builder.dart';
import 'customer_dashboard_middle.dart';
import 'customer_dashboard_narrow.dart';
import 'customer_dashboard_wide.dart';

class CustomerDashboardLayout extends PageLayoutBuilder {
  const CustomerDashboardLayout({
    super.key,
  });

  @override
  Widget buildNarrow(BuildContext context) {
    return const CustomerDashboardNarrow();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const CustomerDashboardMiddle();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const CustomerDashboardWide();
  }
}