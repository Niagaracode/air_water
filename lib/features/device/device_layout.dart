import 'package:air_water/features/device/view/device_middle.dart';
import 'package:air_water/features/device/view/device_narrow.dart';
import 'package:air_water/features/device/view/device_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class DeviceLayout extends PageLayoutBuilder {
  const DeviceLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const DeviceNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const DeviceMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const DeviceWide();
}