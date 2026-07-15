import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import '../header/screen_header.dart';
import '../sidebar/screen_sidebar.dart';

class CustomerLayoutWide extends StatelessWidget {

  final Widget child;
  final UserRole userRole;

  const CustomerLayoutWide({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(userRole: userRole, isNarrow: false),
          Expanded(child: child),
        ],
      ),
    );
  }
}