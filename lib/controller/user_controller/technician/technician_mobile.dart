import 'package:flutter/material.dart';
import 'package:air_water/controller/widgets/mobile_screen_shell.dart';

class TechnicianMobile extends StatelessWidget {
  final Widget child;

  const TechnicianMobile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(child: child);
  }
}