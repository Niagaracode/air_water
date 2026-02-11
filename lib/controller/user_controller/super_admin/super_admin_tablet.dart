import 'package:air_water/controller/widgets/tablet_screen_shell.dart';
import 'package:flutter/material.dart';

class SuperAdminTablet extends StatelessWidget {
  final Widget child;

  const SuperAdminTablet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TabletScreenShell(child: child);
  }
}