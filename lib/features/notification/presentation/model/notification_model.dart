class NotificationModel {
  final int id;
  final int? ruleId;
  final int? tankId;
  final String? parameterType;
  final dynamic value;
  final String? importance;
  final String? status;
  final String? createdAt;
  final String? ruleName;
  final String? tankNumber;
  final String? plantName;
  final String? companyName;

  NotificationModel({
    required this.id,
    this.ruleId,
    this.tankId,
    this.parameterType,
    this.value,
    this.importance,
    this.status,
    this.createdAt,
    this.ruleName,
    this.tankNumber,
    this.plantName,
    this.companyName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      ruleId: json['rule_id'] as int?,
      tankId: json['tank_id'] as int?,
      parameterType: json['parameter_type'] as String?,
      value: json['value'],
      importance: json['importance'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      ruleName: json['rule_name'] as String?,
      tankNumber: json['tank_number'] as String?,
      plantName: json['plant_name'] as String?,
      companyName: json['company_name'] as String?,
    );
  }
}

class NotificationSummary {
  final int criticalLevel;
  final int lowLevel;
  final int lowBattery;
  final int others;
  final int total;

  NotificationSummary({
    required this.criticalLevel,
    required this.lowLevel,
    required this.lowBattery,
    required this.others,
    required this.total,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      criticalLevel: json['critical_level'] as int? ?? 0,
      lowLevel: json['low_level'] as int? ?? 0,
      lowBattery: json['low_battery'] as int? ?? 0,
      others: json['others'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  factory NotificationSummary.empty() {
    return NotificationSummary(
      criticalLevel: 0,
      lowLevel: 0,
      lowBattery: 0,
      others: 0,
      total: 0,
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> data;
  final NotificationPagination pagination;

  NotificationResponse({required this.data, required this.pagination});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => NotificationModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: NotificationPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class NotificationPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  NotificationPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
