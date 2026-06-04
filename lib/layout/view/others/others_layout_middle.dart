import 'package:flutter/material.dart';

class OthersLayoutMiddle extends StatelessWidget {
  final Widget child;
  const OthersLayoutMiddle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("SuperAdminNarrow")),
    );
  }
}