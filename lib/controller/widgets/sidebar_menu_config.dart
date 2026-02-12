import 'package:flutter/material.dart';
import '../../core/user_config/user_role.dart';
import 'sidebar_menu_item.dart';


const mainMenu = [
  SidebarMenuItem(
    key: 'Dashboard',
    label: 'Dashboard',
    icon: Icons.home_rounded,
    allowedRoles: UserRole.values, // all roles
  ),
];


const configurationMenu = [
  SidebarMenuItem(
    key: 'Company',
    label: 'Company',
    icon: Icons.business_rounded,
    allowedRoles: [UserRole.superAdmin], // 👈 only super admin
  ),
  SidebarMenuItem(
    key: 'Plant',
    label: 'Plant',
    icon: Icons.local_florist_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
  SidebarMenuItem(
    key: 'Tank',
    label: 'Tank',
    icon: Icons.storage_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
      UserRole.distributor,
    ],
  ),
  SidebarMenuItem(
    key: 'Device',
    label: 'Device',
    icon: Icons.settings_input_component_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
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
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
  SidebarMenuItem(
    key: 'Group',
    label: 'Group',
    icon: Icons.groups_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
];

const eventsMenu = [
  SidebarMenuItem(
    key: 'Rule',
    label: 'Rule',
    icon: Icons.gavel_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
  SidebarMenuItem(
    key: 'Message Template',
    label: 'Message Template',
    icon: Icons.forum_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
  SidebarMenuItem(
    key: 'Roaster',
    label: 'Roaster',
    icon: Icons.people_alt_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
  SidebarMenuItem(
    key: 'Report',
    label: 'Report',
    icon: Icons.assessment_rounded,
    allowedRoles: [
      UserRole.superAdmin,
      UserRole.companyAdmin,
    ],
  ),
];