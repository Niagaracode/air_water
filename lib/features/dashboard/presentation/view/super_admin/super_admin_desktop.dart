import 'package:air_water/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:flutter/material.dart';

class SuperAdminDesktop extends StatelessWidget {
  const SuperAdminDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      child: const Scaffold(
        body: Center(child: Text('Super Admin Dashboard - Desktop')),
      ),
    );
  }
}
