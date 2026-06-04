import 'package:flutter/material.dart';
import '../../../core/user_config/user_role.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/screen_sidebar.dart';

class OthersLayoutWide extends StatelessWidget {
  const OthersLayoutWide({super.key, required this.child, required this.userRole});
  final UserRole userRole;
  final Widget child;

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
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}