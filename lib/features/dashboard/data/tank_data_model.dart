class TankDataModel {
  final int id;
  final String tankName;
  final String siteName;
  final String deviceId;
  final String siteLocation;
  final double level;
  final double pressure;
  final double batteryV;
  final double solarV;
  final double capacity;
  final double currentVolume;
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
    required this.siteLocation,
    required this.level,
    required this.pressure,
    required this.batteryV,
    required this.solarV,
    required this.capacity,
    required this.currentVolume,
    required this.status,
    required this.lastUpdate,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  // Factory method to create from JSON
  factory TankDataModel.fromJson(Map<String, dynamic> json) {
    // Parse level - handle null values
    double level = 0.0;
    if (json['level'] != null) {
      level = json['level'] is int
          ? (json['level'] as int).toDouble()
          : json['level'].toDouble();
    }

    // Parse prs - handle null values
    double pressure = 0.0;
    if (json['ptn'] != null) {
      pressure = json['ptn'] is int
          ? (json['ptn'] as int).toDouble()
          : json['ptn'].toDouble();
    }



    // battery volt - handle null values
    double battery = 0.0;
    if (json['bat'] != null) {
      battery = json['bat'] is int
          ? (json['bat'] as int).toDouble()
          : json['bat'].toDouble();
    }

    // solar volt - handle null values
    double solar = 0.0;
    if (json['sol'] != null) {
      solar = json['sol'] is int
          ? (json['sol'] as int).toDouble()
          : json['sol'].toDouble();
    }

    // Parse capacity
    double capacity = 0.0;
    if (json['capacity'] != null) {
      capacity = double.tryParse(json['capacity'].toString()) ?? 0.0;
    }

    // Parse currentVolume - handle null values
    double currentVolume = 0.0;
    if (json['currentVolume'] != null) {
      currentVolume = json['currentVolume'] is int
          ? (json['currentVolume'] as int).toDouble()
          : json['currentVolume'].toDouble();
    }

    // Parse lastUpdate
    DateTime lastUpdate = DateTime.now();
    if (json['lastUpdate'] != null) {
      lastUpdate = DateTime.parse(json['lastUpdate']);
    } else if (json['date'] != null && json['time'] != null) {
      // Fallback to date and time fields if lastUpdate is null
      try {
        final dateStr = json['date'];
        final timeStr = json['time'];
        lastUpdate = DateTime.parse('$dateStr $timeStr');
      } catch (e) {
        lastUpdate = DateTime.now();
      }
    }

    // Parse latitude and longitude
    double latitude = 0.0;
    double longitude = 0.0;
    if (json['latitude'] != null) {
      latitude = double.tryParse(json['latitude'].toString()) ?? 0.0;
    }
    if (json['longitude'] != null) {
      longitude = double.tryParse(json['longitude'].toString()) ?? 0.0;
    }

    return TankDataModel(
      id: json['id'],
      tankName: json['name'] ?? 'Unknown',
      siteName: json['siteName'] ?? 'Unknown Site',
      deviceId: json['device_id'] ?? 'Unknown id',
      siteLocation: json['siteLocation'] ?? 'Unknown Location',
      level: level,
      pressure: pressure,
      batteryV: battery,
      solarV: solar,
      capacity: capacity,
      currentVolume: currentVolume,
      status: json['status'] ?? 'Unknown',
      lastUpdate: lastUpdate,
      region: json['region'] ?? 'Unknown Region',
      latitude: latitude,
      longitude: longitude,
    );
  }
}