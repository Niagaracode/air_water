import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app_startup/app_startup.dart';
import '../../../../../core/responsive/screen_layout_builder.dart';
import '../../../../auth/presentation/controllers/auth_providers.dart';
import '../dashboard_shell.dart';

class SuperAdminLayout extends ScreenLayoutBuilder {
  const SuperAdminLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const SuperAdminMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const DashboardShell(child: SuperAdminTablet());
  }

  @override
  Widget buildWide(BuildContext context) {
    return const DashboardShell(child: SuperAdminDesktop());
  }
}

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

              await ref.read(appStartupProvider.notifier).setUnauthenticated();
            },
          ),
        ],
      ),
      body: const Center(child: Text("Super Admin Dashboard - Mobile")),
    );
  }
}

class SuperAdminTablet extends StatelessWidget {
  const SuperAdminTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Super Admin Dashboard - Tablet'));
  }
}

class SuperAdminDesktop extends StatelessWidget {
  const SuperAdminDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Super Admin Dashboard - Desktop'));
  }
}
