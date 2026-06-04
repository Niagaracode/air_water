import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/user_config/user_role_provider.dart';
import 'layout_selector.dart';

class ScreenController extends ConsumerWidget {
  final Widget child;

  const ScreenController({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final role = ref.watch(userRoleProvider);

    if (role == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutSelector(
      userRole: role,
      child: child,
    );
  }
}