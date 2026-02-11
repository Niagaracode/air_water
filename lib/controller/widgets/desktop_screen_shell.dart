import 'package:flutter/material.dart';

import '../../../../controller/widgets/screen_header.dart';
import 'screen_sidebar.dart';

class DesktopScreenShell extends StatelessWidget {
  final Widget child;

  const DesktopScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const ScreenSidebar(),
          Expanded(
            child: Column(
              children: [
                const ScreenHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}