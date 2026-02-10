
import 'package:air_water/layout/user_layout.dart';
import 'package:flutter/cupertino.dart';

import '../core/responsive/screen_layout_builder.dart';
import '../core/user_config/user_role.dart';

class LayoutSelector extends StatelessWidget {
  const LayoutSelector({super.key, required this.userRole});

  final UserRole userRole;

  ScreenLayoutBuilder getScreenLayout() {
    switch (userRole) {
      case UserRole.superAdmin:
        return const SuperAdminLayout();

      case UserRole.companyAdmin:
        return const CompanyAdminLayout();

      case UserRole.distributor:
        return const DistributorLayout();

      case UserRole.supervisor:
        return const SupervisorLayout();

      case UserRole.technician:
        return const TechnicianLayout();

      case UserRole.customer:
      case UserRole.iotManager:
        return const CustomerLayout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return getScreenLayout();
  }
}