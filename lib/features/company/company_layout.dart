import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/company_wide.dart';
import 'presentation/view/company_middle.dart';
import 'presentation/view/company_narrow.dart';

class CompanyLayout extends PageLayoutBuilder {
  const CompanyLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const CompanyNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const CompanyMiddle();

  @override
  Widget buildWide(BuildContext context) => const CompanyWide();
}
