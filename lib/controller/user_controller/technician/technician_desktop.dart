import 'package:flutter/material.dart';

import '../../../../../controller/widgets/desktop_screen_shell.dart';

class TechnicianDesktop extends StatelessWidget {
  final Widget child;

  const TechnicianDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DesktopScreenShell(child: child);
  }
}