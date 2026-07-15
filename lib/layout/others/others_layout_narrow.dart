import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import '../header/screen_header.dart';
import '../sidebar/screen_sidebar.dart';

class OthersLayoutNarrow extends StatelessWidget {
  final Widget child;
  final UserRole userRole;

  const OthersLayoutNarrow({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: Drawer(
        shape: LinearBorder.none,
        child: ScreenSidebar(
          userRole: userRole, isNarrow: true,
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ScreenHeader(userRole: userRole, isNarrow: true),
      ),
      body: child,
    );
  }
}