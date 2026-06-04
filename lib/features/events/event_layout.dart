import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive/page_layout_builder.dart';
import '../../core/user_config/user_role.dart';
import '../../core/user_config/user_role_provider.dart';
import 'presentation/view/event_narrow.dart';
import 'presentation/view/event_middle.dart';
import 'presentation/view/event_wide.dart';

class EventLayout extends ConsumerWidget {
  const EventLayout({super.key});

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

    if (role == UserRole.customer) {

    }

    return const _EventPage();
  }
}

class _EventPage extends PageLayoutBuilder {
  const _EventPage();

  @override
  Widget buildNarrow(BuildContext context) => const EventNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const EventMiddle();

  @override
  Widget buildWide(BuildContext context) => const EventWide();
}
