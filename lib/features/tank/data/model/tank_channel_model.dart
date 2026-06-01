class TankChannelModel {
  final int id;
  final String name;
  final dynamic value;
  final String readingTime;
  final ThresholdModel threshold;

  TankChannelModel({
    required this.id,
    required this.name,
    required this.value,
    required this.readingTime,
    required this.threshold,
  });

  factory TankChannelModel.fromJson(Map<String, dynamic> json) {
    return TankChannelModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      value: json['value'],
      readingTime: json['cd_ct'] ?? '',
      threshold: ThresholdModel.fromJson(
        json['threshold'] ?? {},
      ),
    );
  }
}

class ThresholdModel {
  final ThresholdValue? critical;
  final ThresholdValue? reorder;
  final ThresholdValue? low;
  final ThresholdValue? dataInterval;
  final ThresholdValue? missingInterval;

  ThresholdModel({
    this.critical,
    this.reorder,
    this.low,
    this.dataInterval,
    this.missingInterval,
  });

  factory ThresholdModel.fromJson(Map<String, dynamic> json) {
    return ThresholdModel(
      critical: json['critical'] != null
          ? ThresholdValue.fromJson(json['critical'])
          : null,
      reorder: json['reorder'] != null
          ? ThresholdValue.fromJson(json['reorder'])
          : null,
      low: json['low'] != null
          ? ThresholdValue.fromJson(json['low'])
          : null,
      dataInterval: json['data_interval'] != null
          ? ThresholdValue.fromJson(json['data_interval'])
          : null,
      missingInterval: json['missing_interval'] != null
          ? ThresholdValue.fromJson(json['missing_interval'])
          : null,
    );
  }
}

class ThresholdValue {
  final dynamic value;

  ThresholdValue({this.value});

  factory ThresholdValue.fromJson(Map<String, dynamic> json) {
    return ThresholdValue(
      value: json['value'],
    );
  }
}