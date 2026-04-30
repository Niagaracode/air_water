import 'package:flutter/material.dart';
import '../../../../../controller/widgets/desktop_screen_shell.dart';
import '../../../core/user_config/user_role.dart';


class SuperAdminDesktop extends StatelessWidget {
  final Widget child;

  const SuperAdminDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DesktopScreenShell(userRole: UserRole.superAdmin, child: child);
  }
}