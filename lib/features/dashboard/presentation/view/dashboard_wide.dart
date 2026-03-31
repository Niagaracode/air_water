import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../../core/user_config/user_role_provider.dart';
import 'package:air_water/features/alarm/presentation/controller/alarm_provider.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/technician_dashboard.dart';

class DashboardWide extends ConsumerStatefulWidget {
  const DashboardWide({super.key});

  @override
  ConsumerState<DashboardWide> createState() => _DashboardWideState();
}

class _DashboardWideState extends ConsumerState<DashboardWide> {
  @override
  void initState() {
    super.initState();
    // Initial load for dashboard data
    Future.microtask(() {
      ref.read(alarmProvider.notifier).loadAlarms();
      ref.read(tankProvider.notifier).loadGroupedTanks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: 32),
            roleAsync.when(
              data: (role) {
                if (role == UserRole.technician) {
                  return const TechnicianDashboard();
                }
                
                return const Center(
                  child: Text(
                    'Admin Dashboard Content Coming Soon',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}