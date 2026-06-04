import 'package:flutter/material.dart';

class CustomerLayoutWide extends StatelessWidget {
  final Widget child;

  const CustomerLayoutWide({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("CustomerWide")),
    );
  }
}

