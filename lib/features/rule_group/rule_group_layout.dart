import 'package:air_water/features/rule_group/view/rule_group_middle.dart';
import 'package:air_water/features/rule_group/view/rule_group_narrow.dart';
import 'package:air_water/features/rule_group/view/rule_group_wide.dart';
import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';

class RuleGroupLayout extends PageLayoutBuilder {
  const RuleGroupLayout({super.key});

  @override
  Widget buildWide(BuildContext context) => const RuleGroupWide();

  @override
  Widget buildMiddle(BuildContext context) => const RuleGroupMiddle();

  @override
  Widget buildNarrow(BuildContext context) => const RuleGroupNarrow();
}