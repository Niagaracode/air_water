import 'package:flutter/material.dart';

class CustomerWide extends StatelessWidget {
  final Widget child;

  const CustomerWide({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("CustomerWide")),
    );
  }
}

