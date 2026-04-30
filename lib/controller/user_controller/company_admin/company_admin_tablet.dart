import 'package:flutter/material.dart';

class CompanyAdminTablet extends StatelessWidget {
  const CompanyAdminTablet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Company Admin - Tablet')),
    );
  }
}