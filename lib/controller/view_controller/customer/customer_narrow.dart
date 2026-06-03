import 'package:flutter/material.dart';

class CustomerNarrow extends StatelessWidget {
  final Widget child;

  const CustomerNarrow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("CustomerNarrow")),
    );
  }
}