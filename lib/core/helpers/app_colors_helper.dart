import 'package:flutter/material.dart';

class AppColorsHelper {
  AppColorsHelper._();

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