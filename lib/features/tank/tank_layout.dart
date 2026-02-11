import 'package:air_water/features/tank/view/tank_middle.dart';
import 'package:air_water/features/tank/view/tank_narrow.dart';
import 'package:air_water/features/tank/view/tank_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class TankLayout extends PageLayoutBuilder {
  const TankLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const TankNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const TankMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const TankWide();
}