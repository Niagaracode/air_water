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
  final String gasType;
  final String city;
  final String addressLine_1;
  final String addressLine_2;
  final String addressLine_3;
  final double level;
  final double pressure;
  final double batteryV;
  final double solarV;
  final String status;
  final DateTime lastUpdate;
  final String region;
  final double latitude;
  final double longitude;
  final String thresholds;
  final String channelStatus;

  final int minLevel;
  final int maxLevel;

  TankDataModel({
    required this.id,
    required this.tankName,
    required this.siteName,
    required this.deviceId,
    required this.gasType,
    required this.city,
    required this.addressLine_1,
    required this.addressLine_2,
    required this.addressLine_3,
    required this.level,
    required this.pressure,
    required this.batteryV,
    required this.solarV,
    required this.status,
    required this.lastUpdate,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.thresholds,
    required this.channelStatus,
    required this.minLevel,
    required this.maxLevel,
  });

  factory TankDataModel.fromJson(Map<String, dynamic> json) {
    return TankDataModel(
      id: json['id'],
      tankName: json['name'] ?? 'Unknown',
      siteName: json['siteName'] ?? 'Unknown',
      deviceId: json['device_id'] ?? '',
      gasType: json['product_name'] ?? '',
      city: json['city'] ?? '',
      addressLine_1: json['address_line_1'] ?? '',
      addressLine_2: json['address_line_2'] ?? '',
      addressLine_3: json['address_line_3'] ?? '',
      level: _toDouble(json['level']),
      pressure: _toDouble(json['ptn']),
      batteryV: _toDouble(json['bat']),
      solarV: _toDouble(json['sol']),
      status: json['status'] ?? 'Unknown',
      lastUpdate: parseDateTime(json['lastUpdate']),
      region: json['region'] ?? '',
      latitude: double.tryParse('${json['latitude']}') ?? 0,
      longitude: double.tryParse('${json['longitude']}') ?? 0,
      thresholds: json['thresholds'] ?? '00:00_3.5_25.0_1.0_20.0',
      channelStatus: json['channel_status'] ?? '1_1_1_1',
      minLevel: json['minLevel'] ?? 0,
      maxLevel: json['maxLevel'] ?? 100,
    );
  }

  TankThreshold get thresholdValues => TankThreshold.fromString(thresholds);

  List<String> get _channelParts => channelStatus.split('_');

  bool get isBatteryEnabled =>
      _channelParts.isNotEmpty && _channelParts[0] == '1';

  bool get isLevelEnabled =>
      _channelParts.length > 1 && _channelParts[1] == '1';

  bool get isPressureEnabled =>
      _channelParts.length > 2 && _channelParts[2] == '1';

  bool get isSolarEnabled =>
      _channelParts.length > 3 && _channelParts[3] == '1';

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
      gasType: gasType,
      city: city,
      addressLine_1: addressLine_1,
      addressLine_2: addressLine_2,
      addressLine_3: addressLine_3,
      level: level ?? this.level,
      pressure: pressure ?? this.pressure,
      batteryV: batteryV ?? this.batteryV,
      solarV: solarV ?? this.solarV,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      region: region,
      latitude: latitude,
      longitude: longitude,
      thresholds: thresholds,
      channelStatus: channelStatus,
      minLevel: minLevel,
      maxLevel: maxLevel,
    );
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

class RegionModel {
  final int id;
  final String name;

  RegionModel({
    required this.id,
    required this.name,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

