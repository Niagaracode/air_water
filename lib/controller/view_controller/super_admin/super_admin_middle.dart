import 'package:flutter/material.dart';

class SuperAdminMiddle extends StatelessWidget {
  final Widget child;

  const SuperAdminMiddle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("SuperAdminMiddle")),
    );
  }
}