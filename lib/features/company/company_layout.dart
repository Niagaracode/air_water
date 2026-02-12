import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/company_wide.dart';

class CompanyLayout extends PageLayoutBuilder {
  const CompanyLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const CompanyWide();

  @override
  Widget buildMiddle(BuildContext context) => const CompanyWide();

  @override
  Widget buildWide(BuildContext context) => const CompanyWide();
}
