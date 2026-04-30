import 'package:flutter/material.dart';

import '../../../../controller/widgets/screen_header.dart';
import '../../core/app_theme/app_theme.dart';
import '../../core/user_config/user_role.dart';
import 'screen_sidebar.dart';

class DesktopScreenShell extends StatelessWidget {
  final Widget child;
  final UserRole userRole;

  const DesktopScreenShell({super.key, required this.child, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ScreenHeader(),
          Expanded(
            child: Row(
              children: [
                ScreenSidebar(userRole: userRole),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}