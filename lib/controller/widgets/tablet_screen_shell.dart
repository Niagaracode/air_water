import 'package:air_water/controller/widgets/screen_header.dart';
import 'package:air_water/controller/widgets/screen_sidebar.dart';
import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';

class TabletScreenShell extends StatelessWidget {
  final Widget child;
  final UserRole userRole;
  const TabletScreenShell({super.key, required this.child, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          ScreenSidebar(userRole: userRole),
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