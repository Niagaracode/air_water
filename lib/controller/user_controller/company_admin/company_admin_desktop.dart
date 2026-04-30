import 'package:flutter/material.dart';

import '../../../core/user_config/user_role.dart';
import '../../widgets/desktop_screen_shell.dart';

class CompanyAdminDesktop extends StatelessWidget {
  const CompanyAdminDesktop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DesktopScreenShell(userRole: UserRole.companyAdmin, child: child);
  }
}