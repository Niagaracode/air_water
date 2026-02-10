import 'package:flutter/material.dart';

import '../core/responsive/screen_layout_builder.dart';
import '../features/dashboard/presentation/view/company_admin/company_admin_desktop.dart';
import '../features/dashboard/presentation/view/company_admin/company_admin_mobile.dart';
import '../features/dashboard/presentation/view/company_admin/company_admin_tablet.dart';
import '../features/dashboard/presentation/view/customer/customer_desktop.dart';
import '../features/dashboard/presentation/view/customer/customer_mobile.dart';
import '../features/dashboard/presentation/view/customer/customer_tablet.dart';
import '../features/dashboard/presentation/view/distributor/distributor_desktop.dart';
import '../features/dashboard/presentation/view/distributor/distributor_mobile.dart';
import '../features/dashboard/presentation/view/distributor/distributor_tablet.dart';
import '../features/dashboard/presentation/view/super_admin/super_admin_desktop.dart';
import '../features/dashboard/presentation/view/super_admin/super_admin_mobile.dart';
import '../features/dashboard/presentation/view/super_admin/super_admin_tablet.dart';
import '../features/dashboard/presentation/view/supervisor/supervisor_desktop.dart';
import '../features/dashboard/presentation/view/supervisor/supervisor_mobile.dart';
import '../features/dashboard/presentation/view/supervisor/supervisor_tablet.dart';
import '../features/dashboard/presentation/view/technician/technician_desktop.dart';
import '../features/dashboard/presentation/view/technician/technician_mobile.dart';
import '../features/dashboard/presentation/view/technician/technician_tablet.dart';

class SuperAdminLayout extends ScreenLayoutBuilder {
  const SuperAdminLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const SuperAdminMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const SuperAdminTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const SuperAdminDesktop();
  }
}

class CompanyAdminLayout extends ScreenLayoutBuilder {
  const CompanyAdminLayout({super.key});

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
  const DistributorLayout({super.key});

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
  const SupervisorLayout({super.key});

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
  const TechnicianLayout({super.key});

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
  const CustomerLayout({super.key});

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
