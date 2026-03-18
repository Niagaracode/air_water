import 'package:flutter/material.dart';
import 'msg_template_wide.dart';

class MsgTemplateMiddle extends StatelessWidget {
  const MsgTemplateMiddle({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, reusing Wide as it's responsive. 
    // In a real scenario, we might want to hide some columns.
    return const MsgTemplateWide();
  }
}