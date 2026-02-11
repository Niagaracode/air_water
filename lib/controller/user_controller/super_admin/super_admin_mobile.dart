import 'package:air_water/controller/widgets/mobile_screen_shell.dart';
import 'package:flutter/material.dart';


class SuperAdminMobile extends StatelessWidget {
  final Widget child;

  const SuperAdminMobile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(child: child);
  }
}

/*
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
}*/
