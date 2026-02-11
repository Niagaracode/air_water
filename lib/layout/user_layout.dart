import 'package:flutter/material.dart';

import '../controller/user_controller/company_admin/company_admin_desktop.dart';
import '../controller/user_controller/company_admin/company_admin_mobile.dart';
import '../controller/user_controller/company_admin/company_admin_tablet.dart';
import '../controller/user_controller/customer/customer_desktop.dart';
import '../controller/user_controller/customer/customer_mobile.dart';
import '../controller/user_controller/customer/customer_tablet.dart';
import '../controller/user_controller/distributor/distributor_desktop.dart';
import '../controller/user_controller/distributor/distributor_mobile.dart';
import '../controller/user_controller/distributor/distributor_tablet.dart';
import '../controller/user_controller/super_admin/super_admin_desktop.dart';
import '../controller/user_controller/super_admin/super_admin_mobile.dart';
import '../controller/user_controller/super_admin/super_admin_tablet.dart';
import '../controller/user_controller/supervisor/supervisor_desktop.dart';
import '../controller/user_controller/supervisor/supervisor_mobile.dart';
import '../controller/user_controller/supervisor/supervisor_tablet.dart';
import '../controller/user_controller/technician/technician_desktop.dart';
import '../controller/user_controller/technician/technician_mobile.dart';
import '../controller/user_controller/technician/technician_tablet.dart';
import '../core/responsive/screen_layout_builder.dart';


class SuperAdminLayout extends ScreenLayoutBuilder {
  const SuperAdminLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) =>
      SuperAdminMobile(child: child);

  @override
  Widget buildMiddle(BuildContext context) =>
      SuperAdminTablet(child: child);

  @override
  Widget buildWide(BuildContext context) =>
      SuperAdminDesktop(child: child);
}

class CompanyAdminLayout extends ScreenLayoutBuilder {
  const CompanyAdminLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return const CompanyAdminMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const CompanyAdminTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const CompanyAdminDesktop();
  }
}

class DistributorLayout extends ScreenLayoutBuilder {
  const DistributorLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return const DistributorMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const DistributorTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const DistributorDesktop();
  }
}

class SupervisorLayout extends ScreenLayoutBuilder {
  const SupervisorLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return const SupervisorMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const SupervisorTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const SupervisorDesktop();
  }
}

class TechnicianLayout extends ScreenLayoutBuilder {
  const TechnicianLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return const TechnicianMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const TechnicianTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const TechnicianDesktop();
  }
}

class CustomerLayout extends ScreenLayoutBuilder {
  const CustomerLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return const CustomerMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const CustomerTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const CustomerDesktop();
  }
}
