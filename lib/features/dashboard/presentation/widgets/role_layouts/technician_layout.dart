import 'package:flutter/material.dart';

import '../../../../../core/responsive/screen_layout_builder.dart';
import '../dashboard_shell.dart';

class TechnicianLayout extends ScreenLayoutBuilder {
  const TechnicianLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const _TechnicianMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const DashboardShell(child: _TechnicianTablet());
  }

  @override
  Widget buildWide(BuildContext context) {
    return const DashboardShell(child: _TechnicianDesktop());
  }
}

class _TechnicianMobile extends StatelessWidget {
  const _TechnicianMobile();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Technician - Mobile')));
  }
}

class _TechnicianTablet extends StatelessWidget {
  const _TechnicianTablet();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Technician - Tablet'));
  }
}

class _TechnicianDesktop extends StatelessWidget {
  const _TechnicianDesktop();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Technician - Desktop'));
  }
}
