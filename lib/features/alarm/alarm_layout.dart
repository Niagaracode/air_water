import 'package:flutter/material.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'view/alarm_wide.dart';

class AlarmLayout extends PageLayoutBuilder {
  const AlarmLayout({super.key});

  @override
  Widget buildWide(BuildContext context) => const AlarmWide();

  @override
  Widget buildMiddle(BuildContext context) => const AlarmWide();

  @override
  Widget buildNarrow(BuildContext context) => const AlarmWide();
}
