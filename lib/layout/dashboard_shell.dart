import 'package:flutter/material.dart';
import 'dashboard_sidebar.dart';
import 'dashboard_header.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final bool showSidebar;
  final bool showHeader;

  const DashboardShell({
    super.key,
    required this.child,
    this.showSidebar = true,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        children: [
          if (showSidebar) const DashboardSidebar(),
          Expanded(
            child: Column(
              children: [
                if (showHeader) const DashboardHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
