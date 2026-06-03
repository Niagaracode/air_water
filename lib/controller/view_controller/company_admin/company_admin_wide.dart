import 'package:flutter/material.dart';

import '../../../core/user_config/user_role.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/screen_sidebar.dart';

class CompanyAdminWide extends StatelessWidget {
  const CompanyAdminWide({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ScreenHeader(),
          Expanded(
            child: Row(
              children: [
                ScreenSidebar(userRole: UserRole.companyAdmin),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}