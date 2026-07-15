import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import '../sidebar/screen_sidebar.dart';

class OthersLayoutMiddle extends StatelessWidget {

  final Widget child;
  final UserRole userRole;

  const OthersLayoutMiddle({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: Drawer(
        child: ScreenSidebar(
          userRole: userRole, isNarrow: false,
        ),
      ),
      appBar: AppBar(title: Text(userRole.name)),
      body: child,
    );
  }
}