import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app_startup/app_startup.dart';
import '../../../../auth/presentation/controllers/auth_providers.dart';

class SuperAdminMobile extends ConsumerWidget {
  const SuperAdminMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();

              await ref
                  .read(appStartupProvider.notifier)
                  .setUnauthenticated();
            },
          )
        ],
      ),
      body: const Center(
        child: Text("Super Admin Dashboard - Mobile"),
      ),
    );
  }
}