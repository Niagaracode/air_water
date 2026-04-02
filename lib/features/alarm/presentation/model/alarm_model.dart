class Alarm {
  final int id;
  final String ruleName;
  final String plantName;
  final String tankNumber;
  final String parameterType;
  final String conditionType;
  final double threshold1;
  final double? threshold2;
  final double currentValue;
  final String importance; // High, Medium, Low
  final DateTime triggeredAt;
  final String status; // Active, Resolved

  Alarm({
    required this.id,
    required this.ruleName,
    required this.plantName,
    required this.tankNumber,
    required this.parameterType,
    required this.conditionType,
    required this.threshold1,
    this.threshold2,
    required this.currentValue,
    required this.importance,
    required this.triggeredAt,
    this.status = 'Active',
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Alarm(
      id: json['id'] as int? ?? 0,
      ruleName: json['rule_name'] as String? ?? 'Unnamed Rule',
      plantName: json['plant_name'] as String? ?? 'Generic Plant',
      tankNumber: json['tank_number'] as String? ?? 'Generic Tank',
      parameterType: json['parameter_type'] as String? ?? 'Unknown',
      conditionType: json['condition_type'] as String? ?? 'UNKNOWN',
      threshold1: toDouble(json['threshold_1']),
      threshold2: toDouble(json['threshold_2']),
      currentValue: toDouble(json['triggered_value']),
      importance: json['importance'] as String? ?? 'Medium',
      triggeredAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'Active',
    );
  }
}

class AlarmResponse {
  final List<Alarm> data;
  final AlarmPagination pagination;

  AlarmResponse({required this.data, required this.pagination});

  factory AlarmResponse.fromJson(Map<String, dynamic> json) {
    return AlarmResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => Alarm.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: AlarmPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AlarmPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  AlarmPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AlarmPagination.fromJson(Map<String, dynamic> json) {
    return AlarmPagination(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
