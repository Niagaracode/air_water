import 'package:air_water/controller/widgets/mobile_screen_shell.dart';
import 'package:flutter/material.dart';

import '../../../core/user_config/user_role.dart';


class SuperAdminMobile extends StatelessWidget {
  final Widget child;
  const SuperAdminMobile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(userRole: UserRole.superAdmin,
    child: child);
  }
}