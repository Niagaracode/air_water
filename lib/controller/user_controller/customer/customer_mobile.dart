import 'package:air_water/controller/widgets/mobile_screen_shell.dart';
import 'package:flutter/material.dart';

class CustomerMobile extends StatelessWidget {
  final Widget child;

  const CustomerMobile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(child: child);
  }
}