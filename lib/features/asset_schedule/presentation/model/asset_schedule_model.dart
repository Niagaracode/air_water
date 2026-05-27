class AssetScheduleForecast {
  final DateTime date;
  final double? value; // Level %
  final double? batteryValue; // Battery V
  final double? pressureValue; // Pressure (bar)
  final double? solarValue; // Solar V
  final String status; // 'normal', 'warning', 'critical'

  AssetScheduleForecast({
    required this.date,
    this.value,
    this.batteryValue,
    this.pressureValue,
    this.solarValue,
    required this.status,
  });
}

class AssetScheduleModel {
  final int plantId;
  final String plantName;
  final int tankId;
  final String tankNumber;
  final String deviceId;
  final String siteLocation; // "City, State"
  final DateTime? nextScheduledRefill;
  final DateTime? runoutDate;
  final String unit; // e.g. "% Full"
  final List<AssetScheduleForecast> forecast;

  AssetScheduleModel({
    required this.plantId,
    required this.plantName,
    required this.tankId,
    required this.tankNumber,
    required this.deviceId,
    required this.siteLocation,
    this.nextScheduledRefill,
    this.runoutDate,
    required this.unit,
    required this.forecast,
  });
}
