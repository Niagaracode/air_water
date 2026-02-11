import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/user_config/user_role_provider.dart';
import '../layout/layout_selector.dart';

class ScreenController extends ConsumerWidget {
  final Widget child;

  const ScreenController({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) => LayoutSelector(
        userRole: role,
        child: child,
      ),
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(e.toString()))),
    );
  }
}