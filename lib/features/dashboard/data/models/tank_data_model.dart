import 'package:intl/intl.dart';

class TankDataModel {
  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  final int id;
  final String tankName;
  final String siteName;
  final String deviceId;
  final String city;
  final double level;
  final double pressure;
  final double batteryV;
  final double solarV;
  final String thresholds;
  final String status;
  final DateTime lastUpdate;
  final String region;
  final double latitude;
  final double longitude;

  TankDataModel({
    required this.id,
    required this.tankName,
    required this.siteName,
    required this.deviceId,
    required this.city,
    required this.level,
    required this.pressure,
    required this.batteryV,
    required this.solarV,
    required this.thresholds,
    required this.status,
    required this.lastUpdate,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  factory TankDataModel.fromJson(Map<String, dynamic> json) {
    return TankDataModel(
      id: json['id'],
      tankName: json['name'] ?? 'Unknown',
      siteName: json['siteName'] ?? 'Unknown',
      deviceId: json['device_id'] ?? '',
      city: json['city'] ?? '',
      level: _toDouble(json['level']),
      pressure: _toDouble(json['ptn']),
      batteryV: _toDouble(json['bat']),
      solarV: _toDouble(json['sol']),
      thresholds: json['thresholds'] ?? '00:00_3.5_25.0_1.0_20.0',
      status: json['status'] ?? 'Unknown',
      lastUpdate: _parseDateTime(json['lastUpdate']),
      region: json['region'] ?? '',
      latitude: double.tryParse('${json['latitude']}') ?? 0,
      longitude: double.tryParse('${json['longitude']}') ?? 0,
    );
  }

  TankThreshold get thresholdValues => TankThreshold.fromString(thresholds);

  TankDataModel copyWith({
    double? level,
    double? pressure,
    double? batteryV,
    double? solarV,
    String? status,
    DateTime? lastUpdate,
  }) {
    return TankDataModel(
      id: id,
      tankName: tankName,
      siteName: siteName,
      deviceId: deviceId,
      city: city,
      level: level ?? this.level,
      pressure: pressure ?? this.pressure,
      batteryV: batteryV ?? this.batteryV,
      solarV: solarV ?? this.solarV,
      thresholds: thresholds,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      region: region,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    final str = value.toString().trim();
    // Invalid server value
    if (str == '0.0 0.0' || str.isEmpty) {
      return DateTime.now().subtract(const Duration(days: 365));
    }
    try {
      return DateFormat('dd/MM/yyyy HH:mm:ss').parse(str);
    } catch (e) {
      return DateTime.now().subtract(const Duration(days: 365));
    }
  }
}

class TankThreshold {
  final String duration;
  final double battery;
  final String batteryStatus;
  final double level;
  final String levelStatus;
  final double pressure;
  final String pressureStatus;
  final double reorder;
  final String reorderStatus;

  TankThreshold({
    required this.duration,
    required this.battery,
    required this.batteryStatus,
    required this.level,
    required this.levelStatus,
    required this.pressure,
    required this.pressureStatus,
    required this.reorder,
    required this.reorderStatus,
  });

  factory TankThreshold.fromString(String? value) {
    if (value == null || value.isEmpty) {
      return TankThreshold(
        duration: '00:00',
        battery: 0,
        batteryStatus: 'N/A',
        level: 0,
        levelStatus: 'N/A',
        pressure: 0,
        pressureStatus: 'N/A',
        reorder: 0,
        reorderStatus: 'N/A',
      );
    }

    final parts = value.split('_');

    // Handle legacy 5-part format
    if (parts.length == 5) {
      return TankThreshold(
        duration: parts[0],
        battery: double.tryParse(parts[1]) ?? 0,
        batteryStatus: 'N/A',
        level: double.tryParse(parts[2]) ?? 0,
        levelStatus: 'N/A',
        pressure: double.tryParse(parts[3]) ?? 0,
        pressureStatus: 'N/A',
        reorder: double.tryParse(parts[4]) ?? 0,
        reorderStatus: 'N/A',
      );
    }

    // New 9-part format: duration, bat_val, bat_stat, lvl_val, lvl_stat, prs_val, prs_stat, reo_val, reo_stat
    if (parts.length >= 9) {
      return TankThreshold(
        duration: parts[0],
        battery: double.tryParse(parts[1]) ?? 0,
        batteryStatus: parts[2],
        level: double.tryParse(parts[3]) ?? 0,
        levelStatus: parts[4],
        pressure: double.tryParse(parts[5]) ?? 0,
        pressureStatus: parts[6],
        reorder: double.tryParse(parts[7]) ?? 0,
        reorderStatus: parts[8],
      );
    }

    return TankThreshold(
      duration: '00:00',
      battery: 0,
      batteryStatus: 'N/A',
      level: 0,
      levelStatus: 'N/A',
      pressure: 0,
      pressureStatus: 'N/A',
      reorder: 0,
      reorderStatus: 'N/A',
    );
  }
}
