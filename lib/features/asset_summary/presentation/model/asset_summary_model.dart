// Asset Summary Feature Models
// Self-contained models for the Asset Summary presentation layer.
// These are separate from the Tank and Dashboard models.

// ─────────────────────────────────────────────────────────────────
// AssetSummaryReading
// Represents one parameter row in the asset card (Level, Pressure, etc.)
// ─────────────────────────────────────────────────────────────────
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

  /// Returns a copy with updated fields (used for MQTT live updates)
  AssetSummaryReading copyWith({
    String? item,
    DateTime? readingTime,
    String? readingValue,
    String? product,
    String? importance,
    String? alarmLevels,
    String? deliverable,
    String? rosterName,
  }) {
    return AssetSummaryReading(
      item: item ?? this.item,
      readingTime: readingTime ?? this.readingTime,
      readingValue: readingValue ?? this.readingValue,
      product: product ?? this.product,
      importance: importance ?? this.importance,
      alarmLevels: alarmLevels ?? this.alarmLevels,
      deliverable: deliverable ?? this.deliverable,
      rosterName: rosterName ?? this.rosterName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AssetSummaryGroup
// Represents one tank/device entry in the asset summary list.
// ─────────────────────────────────────────────────────────────────
class AssetSummaryGroup {
  final int tankId;
  final String plantName;
  final String? companyName;
  final String tankNumber;
  final String deviceId;
  final String? deviceName;
  final List<AssetSummaryReading> readings;

  /// Live MQTT data — updated in real-time (nullable until received)
  final AssetSummaryMqttData? mqttData;

  AssetSummaryGroup({
    required this.tankId,
    required this.plantName,
    this.companyName,
    required this.tankNumber,
    required this.deviceId,
    this.deviceName,
    required this.readings,
    this.mqttData,
  });

  /// Returns a copy with live MQTT data applied
  AssetSummaryGroup copyWithMqtt(AssetSummaryMqttData data) {
    return AssetSummaryGroup(
      tankId: tankId,
      plantName: plantName,
      companyName: companyName,
      tankNumber: tankNumber,
      deviceId: deviceId,
      deviceName: deviceName,
      readings: readings,
      mqttData: data,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AssetSummaryMqttData
// Live sensor data received via MQTT for a device.
// Parsed from the cM field: TNP, PTN, KL, CUM, TON, BAT, SOL, GAS
// ─────────────────────────────────────────────────────────────────
class AssetSummaryMqttData {
  final String deviceId;
  final double? level;        // TNP  – Level %
  final double? pressure;     // PTN  – Pressure (bar)
  final double? kl;           // KL   – Kilo Liters (already /1000)
  final double? cubicMeters;  // CUM  – Cubic Meters
  final double? ton;          // TON  – Metric Tons
  final double? batteryVolt;  // BAT  – Battery Voltage
  final double? solarVolt;    // SOL  – Solar Voltage
  final int? gasType;         // GAS  – Gas type code
  final DateTime receivedAt;

  AssetSummaryMqttData({
    required this.deviceId,
    this.level,
    this.pressure,
    this.kl,
    this.cubicMeters,
    this.ton,
    this.batteryVolt,
    this.solarVolt,
    this.gasType,
    required this.receivedAt,
  });

  /// Parse from raw MQTT cM payload string.
  /// Example cM: "10081 TNP:100: TNL:50659: PTN:0.0: GAS:1 : KL:97644 : TON:111.420 : CUM: 85640 : BAT:0.00 : SOL:0.00"
  factory AssetSummaryMqttData.fromCmString(String deviceId, String cmRaw) {
    double? parseVal(String? raw) =>
        raw == null ? null : double.tryParse(raw.trim().replaceAll(':', ''));

    final params = <String, String>{};
    final parts = cmRaw.split(RegExp(r'[\s:]+'));

    for (int i = 0; i < parts.length - 1; i++) {
      final key = parts[i].trim().toUpperCase();
      final val = parts[i + 1].trim();
      if (val.isNotEmpty && double.tryParse(val) != null) {
        params[key] = val;
        i++; // skip value
      }
    }

    // Use regex for reliable key:value extraction
    final regex = RegExp(r'([A-Z]+)\s*:\s*([\d.]+)');
    final matches = regex.allMatches(cmRaw.toUpperCase());
    final parsedParams = <String, String>{};
    for (final m in matches) {
      parsedParams[m.group(1)!] = m.group(2)!;
    }

    final rawKl = parseVal(parsedParams['KL']);
    final kl = rawKl != null ? rawKl / 1000.0 : null;

    return AssetSummaryMqttData(
      deviceId: deviceId,
      level: parseVal(parsedParams['TNP']),
      pressure: parseVal(parsedParams['PTN']),
      kl: kl,
      cubicMeters: parseVal(parsedParams['CUM']),
      ton: parseVal(parsedParams['TON']),
      batteryVolt: parseVal(parsedParams['BAT']),
      solarVolt: parseVal(parsedParams['SOL']),
      gasType: int.tryParse(parsedParams['GAS'] ?? ''),
      receivedAt: DateTime.now(),
    );
  }

  /// Convenience: is the data fresh (received within the last 5 minutes)?
  bool get isLive =>
      DateTime.now().difference(receivedAt).inMinutes < 5;
}

// ─────────────────────────────────────────────────────────────────
// AssetSummaryFilter
// Holds the current filter state for the asset summary list.
// ─────────────────────────────────────────────────────────────────
class AssetSummaryFilter {
  final String? plantFilter;
  final String? tankFilter;
  final String? importanceFilter;

  const AssetSummaryFilter({
    this.plantFilter,
    this.tankFilter,
    this.importanceFilter,
  });

  bool get hasActiveFilter =>
      plantFilter != null || tankFilter != null || importanceFilter != null;

  AssetSummaryFilter copyWith({
    String? plantFilter,
    String? tankFilter,
    String? importanceFilter,
    bool clearPlant = false,
    bool clearTank = false,
    bool clearImportance = false,
  }) {
    return AssetSummaryFilter(
      plantFilter: clearPlant ? null : (plantFilter ?? this.plantFilter),
      tankFilter: clearTank ? null : (tankFilter ?? this.tankFilter),
      importanceFilter:
          clearImportance ? null : (importanceFilter ?? this.importanceFilter),
    );
  }

  static const empty = AssetSummaryFilter();
}
