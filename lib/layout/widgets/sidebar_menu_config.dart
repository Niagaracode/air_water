import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import 'sidebar_menu_item.dart';

const mainMenu = [
  SidebarMenuItem(
    key: 'Dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_rounded,
    iconColor: Colors.indigo,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
      UserRole.customer,
    ],
  ),
];

const configurationMenu = [
  SidebarMenuItem(
    key: 'Site',
    label: 'Site',
    icon: Icons.location_on_rounded,
    iconColor: Colors.green,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),

  SidebarMenuItem(
    key: 'Tank',
    label: 'Tank',
    icon: Icons.water_rounded,
    iconColor: Colors.blue,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),

  SidebarMenuItem(
    key: 'Device',
    label: 'Device',
    icon: Icons.memory_rounded,
    iconColor: Colors.deepPurple,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),

  SidebarMenuItem(
    key: 'Product',
    label: 'Product',
    icon: Icons.inventory_2_rounded,
    iconColor: Colors.orange,
    allowedRoles: [
      UserRole.superAdmin,
    ],
  ),
];

const userMenu = [
  SidebarMenuItem(
    key: 'User',
    label: 'User',
    icon: Icons.person_rounded,
    iconColor: Colors.teal,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),

  SidebarMenuItem(
    key: 'User Group',
    label: 'User Group',
    icon: Icons.groups,
    iconColor: Colors.cyan,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
];

const eventsMenu = [
  SidebarMenuItem(
    key: 'Rule Group',
    label: 'Rule Group',
    icon: Icons.rule_rounded,
    iconColor: Colors.deepOrange,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),

  SidebarMenuItem(
    key: 'Message Template',
    label: 'Message Template',
    icon: Icons.markunread_rounded,
    iconColor: Colors.pink,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),

  SidebarMenuItem(
    key: 'Roster Group',
    label: 'Roster Group',
    icon: Icons.group_work,
    iconColor: Colors.amber,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
];

const reportMenu = [
  SidebarMenuItem(
    key: 'Report',
    label: 'Events',
    icon: Icons.event_rounded,
    iconColor: Colors.red,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
      UserRole.customer,
    ],
  ),

  SidebarMenuItem(
    key: 'Activity',
    label: 'User Activity Logs',
    icon: Icons.history_rounded,
    iconColor: Colors.blueGrey,
    allowedRoles: [
      UserRole.superAdmin,
    ],
  ),
];