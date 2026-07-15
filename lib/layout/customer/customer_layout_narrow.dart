import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import '../sidebar/screen_sidebar.dart';

class CustomerLayoutNarrow extends StatelessWidget {

  final Widget child;
  final UserRole userRole;

  const CustomerLayoutNarrow({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      drawer: Drawer(
        child: ScreenSidebar(
          userRole: userRole, isNarrow: true,
        ),
      ),

      appBar: AppBar(
        title: Text(
          userRole.name,
        ),
      ),

      body: child,
    );
  }
}