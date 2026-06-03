import 'package:flutter/material.dart';

class CompanyAdminMiddle extends StatelessWidget {
  const CompanyAdminMiddle({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Company Admin - Tablet')),
    );
  }
}