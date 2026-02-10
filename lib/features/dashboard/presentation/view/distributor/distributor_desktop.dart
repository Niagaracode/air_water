import 'package:air_water/features/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:flutter/material.dart';

class DistributorDesktop extends StatelessWidget {
  const DistributorDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      child: Scaffold(body: Center(child: Text('Distributor - Desktop'))),
    );
  }
}
