import 'package:air_water/features/rule/view/rule_middle.dart';
import 'package:air_water/features/rule/view/rule_narrow.dart';
import 'package:air_water/features/rule/view/rule_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class RuleLayout extends PageLayoutBuilder {
  const RuleLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const RuleNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const RuleMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const RuleWide();
}