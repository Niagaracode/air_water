import 'package:flutter/cupertino.dart';
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

    switch (userRole) {

      case UserRole.customer:

        return CustomerLayout(
          userRole: userRole,
          child: child,
        );

      case UserRole.superAdmin:
      case UserRole.companyAdmin:

        return OthersLayout(
          userRole: userRole,
          child: child,
        );
    }
  }
}