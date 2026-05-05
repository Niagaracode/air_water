import 'package:flutter/material.dart';
import '../../../../controller/widgets/desktop_screen_shell.dart';
import '../../../core/user_config/user_role.dart';

class CustomerDesktop extends StatelessWidget {
  final Widget child;

  const CustomerDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DesktopScreenShell(userRole: UserRole.customer,
    child: child);
  }
}

