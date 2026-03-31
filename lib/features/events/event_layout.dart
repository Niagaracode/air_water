import 'package:flutter/material.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/event_narrow.dart';
import 'presentation/view/event_middle.dart';
import 'presentation/view/event_wide.dart';

class EventLayout extends PageLayoutBuilder {
  const EventLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const EventNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const EventMiddle();

  @override
  Widget buildWide(BuildContext context) => const EventWide();
}
