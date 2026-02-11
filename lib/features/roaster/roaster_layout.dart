import 'package:air_water/features/roaster/view/roaster_middle.dart';
import 'package:air_water/features/roaster/view/roaster_narrow.dart';
import 'package:air_water/features/roaster/view/roaster_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class RoasterLayout extends PageLayoutBuilder {
  const RoasterLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const RoasterNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const RoasterMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const RoasterWide();
}