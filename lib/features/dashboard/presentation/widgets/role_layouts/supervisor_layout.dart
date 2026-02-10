import 'package:flutter/material.dart';

import '../../../../../core/responsive/screen_layout_builder.dart';
import '../dashboard_shell.dart';

class SupervisorLayout extends ScreenLayoutBuilder {
  const SupervisorLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const _SupervisorMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const DashboardShell(child: _SupervisorTablet());
  }

  @override
  Widget buildWide(BuildContext context) {
    return const DashboardShell(child: _SupervisorDesktop());
  }
}

class _SupervisorMobile extends StatelessWidget {
  const _SupervisorMobile();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Supervisor - Mobile')));
  }
}

class _SupervisorTablet extends StatelessWidget {
  const _SupervisorTablet();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Supervisor - Tablet'));
  }
}

class _SupervisorDesktop extends StatelessWidget {
  const _SupervisorDesktop();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Supervisor - Desktop'));
  }
}
