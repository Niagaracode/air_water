import 'package:flutter/material.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/device_wide.dart';
import 'presentation/view/device_middle.dart';
import 'presentation/view/device_narrow.dart';

class DeviceLayout extends PageLayoutBuilder {
  const DeviceLayout({super.key});

  @override
  Widget buildWide(BuildContext context) => const DeviceWide();

  @override
  Widget buildMiddle(BuildContext context) => const DeviceMiddle();

  @override
  Widget buildNarrow(BuildContext context) => const DeviceNarrow();
}
