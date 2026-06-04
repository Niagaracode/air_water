import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/user_config/user_role_provider.dart';

class DashboardMiddle extends ConsumerWidget {
  const DashboardMiddle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: Text(
          'Admin Dashboard Content Coming Soon',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}