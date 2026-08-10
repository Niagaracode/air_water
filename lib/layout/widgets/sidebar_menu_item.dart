import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';

class SidebarMenuItem {
  final String key;
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<UserRole> allowedRoles;

  const SidebarMenuItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.allowedRoles,
  });
}