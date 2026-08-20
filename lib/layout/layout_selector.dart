import 'package:flutter/material.dart';
import '../core/user_config/user_role.dart';
import 'customer/customer_layout.dart';
import 'others/others_layout.dart';

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
    Widget layout;
    switch (userRole) {
      case UserRole.customer:
        layout = CustomerLayout(
          userRole: userRole,
          child: child,
        );
        break;
      case UserRole.superAdmin:
      case UserRole.companyAdmin:
        layout = OthersLayout(
          userRole: userRole,
          child: child,
        );
        break;
    }
    return SelectionArea(
      child: layout,
    );
  }
}