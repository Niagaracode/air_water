class TankReadingModel {
  final String time;
  final double level;
  final double pressure;
  final double battery;
  final double solar;
  final double volume;
  final DateTime createdAt;

  TankReadingModel({
    required this.time,
    required this.level,
    required this.pressure,
    required this.battery,
    required this.solar,
    required this.volume,
    required this.createdAt,
  });

  factory TankReadingModel.fromJson(Map<String, dynamic> json) {
    return TankReadingModel(
      time: json['time'] ?? '',
      level: (json['level'] ?? 0).toDouble(),
      pressure: (json['pressure'] ?? 0).toDouble(),
      battery: (json['battery'] ?? 0).toDouble(),
      solar: (json['solar'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}