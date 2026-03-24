class AssetSummaryReading {
  final String item;
  final DateTime readingTime;
  final String readingValue;
  final String product;
  final String importance;
  final String alarmLevels;
  final String deliverable;
  final String? rosterName;

  AssetSummaryReading({
    required this.item,
    required this.readingTime,
    required this.readingValue,
    required this.product,
    required this.importance,
    required this.alarmLevels,
    required this.deliverable,
    this.rosterName,
  });
}

class AssetSummaryGroup {
  final int tankId;
  final String plantName;
  final String tankNumber;
  final String deviceId;
  final List<AssetSummaryReading> readings;

  AssetSummaryGroup({
    required this.tankId,
    required this.plantName,
    required this.tankNumber,
    required this.deviceId,
    required this.readings,
  });
}
