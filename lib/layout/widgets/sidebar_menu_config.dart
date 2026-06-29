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

  SidebarMenuItem(
    key: 'Schedule',
    label: 'Schedule',
    icon: Icons.calendar_month_outlined,
    allowedRoles: [UserRole.customer],
  ),
];

const configurationMenu = [
  SidebarMenuItem(
    key: 'Company',
    label: 'Company',
    icon: Icons.business_rounded,
    allowedRoles: [],
  ),
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
  SidebarMenuItem(
    key: 'Tank Dimension',
    label: 'Tank Dimension',
    icon: Icons.straighten_rounded,
    allowedRoles: [UserRole.superAdmin, UserRole.companyAdmin],
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
    key: 'Alarm',
    label: 'Alarm',
    icon: Icons.notifications_active_outlined,
    allowedRoles: [UserRole.customer],
  ),
  SidebarMenuItem(
    key: 'Event',
    label: 'Event',
    icon: Icons.event_note_rounded,
    allowedRoles: [UserRole.customer],
  ),
  SidebarMenuItem(
    key: 'Setting',
    label: 'Setting',
    icon: Icons.settings_rounded,
    allowedRoles: [], // Restricted
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
