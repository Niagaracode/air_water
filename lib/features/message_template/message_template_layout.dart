import 'package:air_water/features/message_template/view/msg_template_middle.dart';
import 'package:air_water/features/message_template/view/msg_template_narrow.dart';
import 'package:air_water/features/message_template/view/msg_template_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class MessageTemplateLayout extends PageLayoutBuilder {
  const MessageTemplateLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const MsgTemplateNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const MsgTemplateMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const MsgTemplateWide();
}