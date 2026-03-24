import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/setting_wide.dart';

class SettingLayout extends PageLayoutBuilder {
  const SettingLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const SettingWide();

  @override
  Widget buildMiddle(BuildContext context) => const SettingWide();

  @override
  Widget buildWide(BuildContext context) => const SettingWide();
}
