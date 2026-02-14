import 'package:flutter/material.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/tank_wide.dart';
import 'presentation/view/tank_middle.dart';
import 'presentation/view/tank_narrow.dart';

class TankLayout extends PageLayoutBuilder {
  const TankLayout({super.key});

  @override
  Widget buildWide(BuildContext context) => const TankWide();

  @override
  Widget buildMiddle(BuildContext context) => const TankMiddle();

  @override
  Widget buildNarrow(BuildContext context) => const TankNarrow();
}
