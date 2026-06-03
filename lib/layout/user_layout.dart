import 'package:flutter/material.dart';

import '../controller/view_controller/company_admin/company_admin_wide.dart';
import '../controller/view_controller/company_admin/company_admin_narrow.dart';
import '../controller/view_controller/company_admin/company_admin_middle.dart';
import '../controller/view_controller/customer/customer_wide.dart';
import '../controller/view_controller/customer/customer_narrow.dart';
import '../controller/view_controller/customer/customer_middle.dart';
import '../controller/view_controller/distributor/distributor_desktop.dart';
import '../controller/view_controller/distributor/distributor_mobile.dart';
import '../controller/view_controller/distributor/distributor_tablet.dart';
import '../controller/view_controller/super_admin/super_admin_wide.dart';
import '../controller/view_controller/super_admin/super_admin_narrow.dart';
import '../controller/view_controller/super_admin/super_admin_middle.dart';
import '../core/responsive/screen_layout_builder.dart';
import '../core/user_config/user_role.dart';


class SuperAdminLayout extends ScreenLayoutBuilder {
  const SuperAdminLayout({super.key, required super.child, required this.userRole});
  final UserRole userRole;

  @override
  Widget buildNarrow(BuildContext context) =>
      SuperAdminNarrow(child: child);

  @override
  Widget buildMiddle(BuildContext context) =>
      SuperAdminMiddle(child: child);

  @override
  Widget buildWide(BuildContext context) =>
      SuperAdminWide(child: child);
}

class CompanyAdminLayout extends ScreenLayoutBuilder {
  const CompanyAdminLayout({super.key, required super.child, required this.userRole});
  final UserRole userRole;

  @override
  Widget buildNarrow(BuildContext context) =>
      CompanyAdminNarrow(child: child);

  @override
  Widget buildMiddle(BuildContext context) =>
      CompanyAdminMiddle(child: child);

  @override
  Widget buildWide(BuildContext context) =>
      CompanyAdminWide(child: child);

}


class CustomerLayout extends ScreenLayoutBuilder {
  const CustomerLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return CustomerNarrow(child: child);
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return CustomerMiddle(child: child);
  }

  @override
  Widget buildWide(BuildContext context) {
    return CustomerWide(child: child);
  }
}