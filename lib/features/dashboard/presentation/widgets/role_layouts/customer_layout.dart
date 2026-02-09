import 'package:flutter/material.dart';

import '../../../../../core/responsive/screen_layout_builder.dart';

class CustomerLayout extends ScreenLayoutBuilder {
  const CustomerLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const _CustomerMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const _CustomerTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const _CustomerDesktop();
  }
}

class _CustomerMobile extends StatelessWidget {
  const _CustomerMobile();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Customer - Mobile')),
    );
  }
}

class _CustomerTablet extends StatelessWidget {
  const _CustomerTablet();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Customer - Tablet')),
    );
  }
}

class _CustomerDesktop extends StatelessWidget {
  const _CustomerDesktop();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Customer - Desktop')),
    );
  }
}