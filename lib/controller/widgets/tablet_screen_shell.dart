import 'package:air_water/controller/widgets/screen_header.dart';
import 'package:air_water/controller/widgets/screen_sidebar.dart';
import 'package:flutter/material.dart';

class TabletScreenShell extends StatelessWidget {
  final Widget child;

  const TabletScreenShell({super.key, required this.child});

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