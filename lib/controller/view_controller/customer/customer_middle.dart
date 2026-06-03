import 'package:flutter/material.dart';

class CustomerMiddle extends StatelessWidget {
  final Widget child;

  const CustomerMiddle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("CustomerMiddle")),
    );
  }
}