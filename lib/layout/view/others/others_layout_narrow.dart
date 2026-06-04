import 'package:flutter/material.dart';

class OthersLayoutNarrow extends StatelessWidget {
  final Widget child;
  const OthersLayoutNarrow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("SuperAdminNarrow")),
    );
  }
}