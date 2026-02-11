import 'package:flutter/material.dart';
import 'sidebar_menu_item.dart';

const mainMenu = [
  SidebarMenuItem(
    key: 'Dashboard',
    label: 'Dashboard',
    icon: Icons.home_rounded,
  ),
];

const configurationMenu = [
  SidebarMenuItem(
    key: 'Plant',
    label: 'Plant',
    icon: Icons.local_florist_rounded,
  ),
  SidebarMenuItem(
    key: 'Tank',
    label: 'Tank',
    icon: Icons.storage_rounded,
  ),
  SidebarMenuItem(
    key: 'Device',
    label: 'Device',
    icon: Icons.settings_input_component_rounded,
  ),
  SidebarMenuItem(
    key: 'Product',
    label: 'Product',
    icon: Icons.category_rounded,
  ),
];

const userMenu = [
  SidebarMenuItem(
    key: 'User',
    label: 'User',
    icon: Icons.person_rounded,
  ),
  SidebarMenuItem(
    key: 'Group',
    label: 'Group',
    icon: Icons.groups_rounded,
  ),
];

const eventsMenu = [
  SidebarMenuItem(
    key: 'Rule',
    label: 'Rule',
    icon: Icons.gavel_rounded,
  ),
  SidebarMenuItem(
    key: 'Message Template',
    label: 'Message Template',
    icon: Icons.forum_rounded,
  ),
  SidebarMenuItem(
    key: 'Roaster',
    label: 'Roaster',
    icon: Icons.people_alt_rounded,
  ),
  SidebarMenuItem(
    key: 'Report',
    label: 'Report',
    icon: Icons.assessment_rounded,
  ),
];