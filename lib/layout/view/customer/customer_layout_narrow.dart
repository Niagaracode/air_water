import 'package:flutter/material.dart';

class CustomerLayoutNarrow extends StatelessWidget {
  final Widget child;

  const CustomerLayoutNarrow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("CustomerNarrow")),
    );
  }
}