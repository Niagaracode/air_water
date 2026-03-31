import 'package:flutter/material.dart';
import 'package:air_water/controller/widgets/tablet_screen_shell.dart';

class TechnicianTablet extends StatelessWidget {
  final Widget child;

  const TechnicianTablet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TabletScreenShell(child: child);
  }
}