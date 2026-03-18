import 'package:flutter/material.dart';
import 'msg_template_wide.dart';

class MsgTemplateNarrow extends StatelessWidget {
  const MsgTemplateNarrow({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, reusing Wide as it's responsive.
    return const MsgTemplateWide();
  }
}