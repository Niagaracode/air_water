import 'package:flutter/material.dart';
import '../../../../controller/widgets/desktop_screen_shell.dart';

class CustomerDesktop extends StatelessWidget {
  final Widget child;

  const CustomerDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DesktopScreenShell(child: child);
  }
}

