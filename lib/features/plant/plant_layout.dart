import 'package:air_water/features/plant/presentation/view/plant_middle.dart';
import 'package:air_water/features/plant/presentation/view/plant_narrow.dart';
import 'package:air_water/features/plant/presentation/view/plant_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class PlantLayout extends PageLayoutBuilder {
  const PlantLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const PlantNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const PlantMiddle();

  @override
  Widget buildWide(BuildContext context) => const PlantWide();
}
