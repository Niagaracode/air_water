import 'package:intl/intl.dart';

import '../../../../shared/utils/app_helper.dart';

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
      lastUpdate: parseDateTime(json['lastUpdate']),
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

}

class TankThreshold {
  final String duration;
  final double battery;
  final double level;
  final double pressure;
  final double reorder;

  TankThreshold({
    required this.duration,
    required this.battery,
    required this.level,
    required this.pressure,
    required this.reorder,
  });

  factory TankThreshold.fromString(String? value) {
    if (value == null || value.isEmpty) {
      return TankThreshold(
        duration: '00:00',//hh:mm
        battery: 0,
        level: 0,
        pressure: 0,
        reorder: 0,
      );
    }

    final parts = value.split('_');

    if (parts.length < 5) {
      return TankThreshold(
        duration: '00:00',
        battery: 0,
        level: 0,
        pressure: 0,
        reorder: 0,
      );
    }

    return TankThreshold(
      duration: parts[0],
      battery: double.tryParse(parts[1]) ?? 0,
      level: double.tryParse(parts[2]) ?? 0,
      pressure: double.tryParse(parts[3]) ?? 0,
      reorder: double.tryParse(parts[4]) ?? 0,
    );
  }
}