import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../widgets/dashboard_header.dart';

class DashboardNarrow extends ConsumerWidget {
  const DashboardNarrow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: 16),
            roleAsync.when(
              data: (role) {
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