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
  final String? subject;
  final String? body;
  final String? statusLabel;

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
    this.subject,
    this.body,
    this.statusLabel,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawRuleName = json['rule_name'] as String?;
    String? resolvedRuleName = rawRuleName;

    if (rawRuleName != null && rawRuleName.toLowerCase() == 'default rule group') {
      final type = (json['parameter_type'] as String?)?.toUpperCase() ?? '';
      final importance = (json['status_label'] as String?) ?? (json['importance'] as String?) ?? 'Alert';
      final rawValue = json['value'] ?? json['triggered_value'];
      
      String valueStr = '';
      if (rawValue != null && rawValue.toString().isNotEmpty) {
        var cleanVal = rawValue.toString();
        if (cleanVal.endsWith('.0000')) cleanVal = cleanVal.substring(0, cleanVal.length - 5);
        if (cleanVal.endsWith('.00')) cleanVal = cleanVal.substring(0, cleanVal.length - 3);
        
        if (type == 'LEVEL') {
          valueStr = ' reached $cleanVal%';
        } else if (type == 'BATTERY') {
          valueStr = ' reached $cleanVal V';
        } else if (type == 'SOLAR') {
          valueStr = ' reached $cleanVal V';
        } else if (type == 'PRESSURE') {
          valueStr = ' reached $cleanVal Bar';
        } else {
          valueStr = ' reached $cleanVal';
        }
      }

      String label = '';
      final capitalizedImportance = importance.isEmpty
          ? ''
          : '${importance[0].toUpperCase()}${importance.substring(1).toLowerCase()}';
      if (type == 'LEVEL') {
        label = '$capitalizedImportance Level';
      } else if (type == 'BATTERY') {
        label = '$capitalizedImportance Battery';
      } else if (type == 'SOLAR') {
        label = '$capitalizedImportance Solar';
      } else if (type == 'PRESSURE') {
        label = '$capitalizedImportance Pressure';
      } else {
        label = '$capitalizedImportance $type';
      }

      resolvedRuleName = '$label$valueStr';
    }

    final commFailRegex = RegExp(
      r'(Comm fail\s+)?device\s+communicate\s+failed(\s+reached\s+\d+)?',
      caseSensitive: false,
    );

    if (resolvedRuleName != null) {
      resolvedRuleName = resolvedRuleName.replaceAll(
        commFailRegex,
        'Device not available offline',
      );
    }

    String? subject = json['subject'] as String?;
    if (subject != null) {
      subject = subject.replaceAll(
        commFailRegex,
        'Device not available offline',
      );
    }

    String? body = json['body'] as String?;
    if (body != null) {
      body = body.replaceAll(
        commFailRegex,
        'Device not available offline',
      );
    }

    String? parameterType = json['parameter_type'] as String?;
    if (parameterType != null) {
      parameterType = parameterType.replaceAll(
        commFailRegex,
        'Device not available offline',
      );
    }

    return NotificationModel(
      id: json['id'] as int,
      ruleId: json['rule_id'] as int?,
      tankId: json['tank_id'] as int?,
      parameterType: parameterType,
      value: json['value'] ?? json['triggered_value'],
      importance: (json['status_label'] as String?) ?? (json['importance'] as String?),
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      ruleName: resolvedRuleName,
      tankNumber: json['tank_number'] as String?,
      plantName: json['plant_name'] as String?,
      companyName: json['company_name'] as String?,
      subject: subject,
      body: body,
      statusLabel: json['status_label'] as String?,
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
