import '../../../../shared/utils/app_helper.dart';

class TankChannelModel {
  final int id;
  final String name;
  final dynamic value;
  final DateTime readingTime;
  final ThresholdModel threshold;
  final bool channelEnable;

  TankChannelModel({
    required this.id,
    required this.name,
    required this.value,
    required this.readingTime,
    required this.threshold,
    required this.channelEnable,
  });

  factory TankChannelModel.fromJson(Map<String, dynamic> json) {
    return TankChannelModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      value: json['value'],
      readingTime: parseDateTime(json['cd_ct']),
      threshold: ThresholdModel.fromJson(
        json['threshold'] is Map ? json['threshold'] : {},
      ),
      channelEnable: json['channel_enable'] == 1,
    );
  }
}

class ThresholdModel {
  final ThresholdValue? full;
  final ThresholdValue? reorder;
  final ThresholdValue? critical;
  final ThresholdValue? low;
  final ThresholdValue? missingInterval;

  ThresholdModel({
    this.full,
    this.reorder,
    this.critical,
    this.low,
    this.missingInterval,
  });

  factory ThresholdModel.fromJson(Map<String, dynamic> json) {

    ThresholdValue? parseThreshold(dynamic value) {
      if (value != null && value is Map) {
        Map<String, dynamic> convertedMap = {};
        value.forEach((key, value) {
          convertedMap[key.toString()] = value;
        });
        return ThresholdValue.fromJson(convertedMap);
      }
      return null;
    }

    return ThresholdModel(
      full: parseThreshold(json['high']),
      reorder: parseThreshold(json['reorder']),
      critical: parseThreshold(json['critical']),
      low: parseThreshold(json['low']),
      missingInterval: parseThreshold(json['missing_interval']),
    );
  }
}

class ThresholdValue {
  final dynamic value;
  final String comparator;
  List<String> rosterIds;

  ThresholdValue({
    this.value,
    required this.comparator,
    required this.rosterIds
  });

  factory ThresholdValue.fromJson(Map<String, dynamic> json) {

    List<String> rosterIds = [];
    if (json['rosterIds'] != null) {
      if (json['rosterIds'] is List) {
        rosterIds = (json['rosterIds'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return ThresholdValue(
      value: json['value'],
      comparator: json['comparator']?.toString() ?? '',
      rosterIds: rosterIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'comparator': comparator,
      'rosterIds': rosterIds,
    };
  }
}