import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import '../header/screen_header.dart';
import '../sidebar/screen_sidebar.dart';

class OthersLayoutWide extends StatelessWidget {

  final Widget child;
  final UserRole userRole;

  const OthersLayoutWide({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(userRole: userRole),
          Expanded(
            child: Row(
              children: [
                ScreenSidebar(userRole: userRole, isNarrow: false),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}