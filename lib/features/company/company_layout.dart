import 'package:air_water/features/company/view/company_middle.dart';
import 'package:air_water/features/company/view/company_narrow.dart';
import 'package:air_water/features/company/view/company_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class CompanyLayout extends PageLayoutBuilder {
  const CompanyLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const CompanyNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const CompanyMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const CompanyWide();
}