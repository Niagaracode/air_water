import 'package:flutter/material.dart';

import '../../../../../core/responsive/screen_layout_builder.dart';

class DistributorLayout extends ScreenLayoutBuilder {
  const DistributorLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const _DistributorMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const _DistributorTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const _DistributorDesktop();
  }
}

class _DistributorMobile extends StatelessWidget {
  const _DistributorMobile();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Distributor - Mobile')),
    );
  }
}

class _DistributorTablet extends StatelessWidget {
  const _DistributorTablet();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Distributor - Tablet')),
    );
  }
}

class _DistributorDesktop extends StatelessWidget {
  const _DistributorDesktop();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Distributor - Desktop')),
    );
  }
}