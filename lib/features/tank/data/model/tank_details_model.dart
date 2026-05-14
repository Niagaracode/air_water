import 'tank_model.dart';

class TankEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String status;
  final String type;

  TankEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  factory TankEvent.fromJson(Map<String, dynamic> json) {
    return TankEvent(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      type: json['type'] as String,
    );
  }
}

class TankReading {
  final String id;
  final String parameter;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String status;

  TankReading({
    required this.id,
    required this.parameter,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.status,
  });

  factory TankReading.fromJson(Map<String, dynamic> json) {
    return TankReading(
      id: json['id'].toString(),
      parameter: json['parameter'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
    );
  }
}

class TankForecast {
  final String id;
  final DateTime timestamp;
  final double predictedValue;
  final double confidence;
  final String predictionType;

  TankForecast({
    required this.id,
    required this.timestamp,
    required this.predictedValue,
    required this.confidence,
    required this.predictionType,
  });

  factory TankForecast.fromJson(Map<String, dynamic> json) {
    return TankForecast(
      id: json['id'].toString(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      predictedValue: (json['predicted_value'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      predictionType: json['prediction_type'] as String,
    );
  }
}

class DataChannel {
  final String name;
  final String currentReading;
  final DateTime lastUpdated;
  final DateTime readingTime;
  final String status;
  final double percentFull;
  final String trend;
  final String deviceName;
  final String ruleName;

  DataChannel({
    required this.name,
    required this.currentReading,
    required this.lastUpdated,
    required this.readingTime,
    required this.status,
    required this.percentFull,
    required this.trend,
    required this.deviceName,
    required this.ruleName,
  });
}

class TankDetailsState {
  final bool isLoading;
  final String? error;
  final Tank? tank;
  final List<TankEvent> events;
  final List<TankReading> readings;
  final List<TankForecast> forecasts;
  final List<DataChannel> dataChannels;
  final List<Map<String, dynamic>> chartData;

  const TankDetailsState({
    this.isLoading = false,
    this.error,
    this.tank,
    this.events = const [],
    this.readings = const [],
    this.forecasts = const [],
    this.dataChannels = const [],
    this.chartData = const [],
  });

  TankDetailsState copyWith({
    bool? isLoading,
    String? error,
    Tank? tank,
    List<TankEvent>? events,
    List<TankReading>? readings,
    List<TankForecast>? forecasts,
    List<DataChannel>? dataChannels,
    List<Map<String, dynamic>>? chartData,
  }) {
    return TankDetailsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      tank: tank ?? this.tank,
      events: events ?? this.events,
      readings: readings ?? this.readings,
      forecasts: forecasts ?? this.forecasts,
      dataChannels: dataChannels ?? this.dataChannels,
      chartData: chartData ?? this.chartData,
    );
  }
}
