import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import 'customer/customer_dashboard_layout.dart';
import 'others/others_dashboard_layout.dart';

class DashboardLayout extends ConsumerWidget {

  const DashboardLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final role = ref.read(userRoleProvider);
    if (role == UserRole.customer) {
      return const CustomerDashboardLayout();
    }
    return const OthersDashboardLayout();
  }
}