import 'package:flutter/material.dart';

import '../../../../../controller/widgets/desktop_screen_shell.dart';

class DistributorDesktop extends StatelessWidget {
  const DistributorDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DesktopScreenShell(
      child: Scaffold(body: Center(child: Text('Distributor - Desktop'))),
    );
  }
}
