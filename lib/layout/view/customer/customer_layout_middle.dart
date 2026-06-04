import 'package:flutter/material.dart';

class CustomerLayoutMiddle extends StatelessWidget {
  final Widget child;

  const CustomerLayoutMiddle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("CustomerMiddle")),
    );
  }
}