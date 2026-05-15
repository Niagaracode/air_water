import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/notification_wide.dart';

class NotificationLayout extends PageLayoutBuilder {
  const NotificationLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const NotificationWide(); // Using Wide for now, can add narrow later

  @override
  Widget buildMiddle(BuildContext context) => const NotificationWide();

  @override
  Widget buildWide(BuildContext context) => const NotificationWide();
}
