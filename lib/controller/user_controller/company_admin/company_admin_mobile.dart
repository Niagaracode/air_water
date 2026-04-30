import 'package:flutter/material.dart';

class CompanyAdminMobile extends StatelessWidget {
  const CompanyAdminMobile({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Company Admin - Mobile')),
    );
  }
}