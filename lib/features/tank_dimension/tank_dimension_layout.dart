import 'package:air_water/features/tank_dimension/presentation/view/tank_dimension_middle.dart';
import 'package:air_water/features/tank_dimension/presentation/view/tank_dimension_narrow.dart';
import 'package:air_water/features/tank_dimension/presentation/view/tank_dimension_wide.dart';
import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';

class TankDimensionLayout extends PageLayoutBuilder {
  const TankDimensionLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const TankDimensionNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const TankDimensionMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const TankDimensionWide();
}
