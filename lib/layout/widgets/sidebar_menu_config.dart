import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import 'sidebar_menu_item.dart';

const mainMenu = [
  SidebarMenuItem(
    key: 'Dashboard',
    label: 'Dashboard',
    icon: Icons.home_rounded,
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
    icon: Icons.local_florist_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
  SidebarMenuItem(
    key: 'Tank',
    label: 'Tank',
    icon: Icons.storage_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
  SidebarMenuItem(
    key: 'Device',
    label: 'Device',
    icon: Icons.settings_input_component_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
  SidebarMenuItem(
    key: 'Product',
    label: 'Product',
    icon: Icons.category_rounded,
    allowedRoles: [UserRole.superAdmin],
  ),
];

const userMenu = [
  SidebarMenuItem(
    key: 'User',
    label: 'User',
    icon: Icons.person_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
  SidebarMenuItem(
    key: 'Asset Group',
    label: 'Asset Group',
    icon: Icons.layers_outlined,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
];

const eventsMenu = [
  SidebarMenuItem(
    key: 'Rule Group',
    label: 'Rule Group',
    icon: Icons.rule_folder_outlined,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
  SidebarMenuItem(
    key: 'Message Template',
    label: 'Message Template',
    icon: Icons.forum_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
  SidebarMenuItem(
    key: 'Roster',
    label: 'Roster Group',
    icon: Icons.people_alt_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
  ),
];

const reportMenu = [
  SidebarMenuItem(
    key: 'Event',
    label: 'Event',
    icon: Icons.event_note_rounded,
    allowedRoles: [UserRole.customer],
  ),

  SidebarMenuItem(
    key: 'Report',
    label: 'Events',
    icon: Icons.assessment_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
      UserRole.customer,
    ],
  ),
];
