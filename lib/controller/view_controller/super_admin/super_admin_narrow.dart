import 'package:flutter/material.dart';


class SuperAdminNarrow extends StatelessWidget {
  final Widget child;
  const SuperAdminNarrow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("SuperAdminNarrow")),
    );
  }
}