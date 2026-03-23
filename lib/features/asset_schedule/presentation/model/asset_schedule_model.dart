class AssetScheduleForecast {
  final DateTime date;
  final double value;
  final String status; // 'normal', 'warning', 'critical'

  AssetScheduleForecast({
    required this.date,
    required this.value,
    required this.status,
  });
}

class AssetScheduleModel {
  final int plantId;
  final String plantName;
  final int tankId;
  final String tankNumber;
  final String item; // e.g. "Level"
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
    required this.item,
    required this.siteLocation,
    this.nextScheduledRefill,
    this.runoutDate,
    required this.unit,
    required this.forecast,
  });
}
