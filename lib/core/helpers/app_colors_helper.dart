import 'package:flutter/material.dart';

import '../app_theme/app_theme.dart';

class AppColorsHelper {
  AppColorsHelper._();

  static final Map<String, Color> _roleColorMap = {
    'super admin': const Color(0xFF6366F1),
    'admin': const Color(0xFF0EA5E9),
    'asset user': const Color(0xFF10B981),
    'end customer': const Color(0xFFF59E0B),
  };

  static Color getGasTypeColor(String gasType) {
    switch (gasType.toUpperCase()) {
      case 'LAR':
        return Colors.teal;
      case 'LCO₂':
      case 'LCO2':
        return Colors.grey;
      case 'LIN':
        return Colors.blueGrey;
      case 'LMO':
        return Colors.brown;
      case 'LOX':
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  static final List<Color> _groupColors = [
    const Color(0xFF6366F1), // indigo
    const Color(0xFF0EA5E9), // sky
    const Color(0xFF10B981), // emerald
    const Color(0xFFF59E0B), // amber
    const Color(0xFFEC4899), // pink
    const Color(0xFF8B5CF6), // violet
    const Color(0xFF14B8A6), // teal
  ];

  static Color colorForRole(String? role) {
    if (role == null || role.trim().isEmpty) return primary;
    return _roleColorMap[role.toLowerCase().trim()] ?? primary;
  }

  static Color colorForGroup(String key) {
    if (key.trim().isEmpty) return primary;
    final hash =
    key.toLowerCase().trim().codeUnits.fold<int>(0, (p, c) => p + c);
    return _groupColors[hash % _groupColors.length];
  }


  static Color getBatSolColor(double level) {
    if (level <= 3) return Colors.red;
    if (level <= 7) return Colors.orange;
    return Colors.green;
  }

  static Color getLevelColor(double level) {
    if (level <= 20) return Colors.red;
    if (level <= 40) return Colors.orange;
    return Colors.green;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;

      case 'warning':
        return Colors.orange;

      case 'critical':
        return Colors.red;

      case 'offline':
        return Colors.grey;

      case 'out of order':
        return Colors.purple;

      default:
        return Colors.blue;
    }
  }
}