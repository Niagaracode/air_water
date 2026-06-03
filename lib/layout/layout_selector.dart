
import 'package:air_water/layout/user_layout.dart';
import 'package:flutter/cupertino.dart';
import '../core/responsive/screen_layout_builder.dart';
import '../core/user_config/user_role.dart';

class LayoutSelector extends StatelessWidget {
  final UserRole userRole;
  final Widget child;

  const LayoutSelector({
    super.key,
    required this.userRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return getScreenLayout(child);
  }

  ScreenLayoutBuilder getScreenLayout(Widget child) {
    switch (userRole) {
      case UserRole.superAdmin:
        return SuperAdminLayout(userRole: userRole,
        child: child);

      case UserRole.companyAdmin:
        return CompanyAdminLayout(userRole: userRole,
        child: child);

      case UserRole.customer:
        return CustomerLayout(child: child);
    }
  }
}