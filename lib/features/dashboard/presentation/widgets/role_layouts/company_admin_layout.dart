import 'package:flutter/material.dart';

import '../../../../../core/responsive/screen_layout_builder.dart';

class CompanyAdminLayout extends ScreenLayoutBuilder {
  const CompanyAdminLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) {
    return const _CompanyAdminMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const _CompanyAdminTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const _CompanyAdminDesktop();
  }
}

class _CompanyAdminMobile extends StatelessWidget {
  const _CompanyAdminMobile();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Company Admin - Mobile')),
    );
  }
}

class _CompanyAdminTablet extends StatelessWidget {
  const _CompanyAdminTablet();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Company Admin - Tablet')),
    );
  }
}

class _CompanyAdminDesktop extends StatelessWidget {
  const _CompanyAdminDesktop();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Company Admin - Desktop')),
    );
  }
}