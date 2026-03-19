class Rule {
  final int id;
  final String name;
  final String? description;
  final int companyId;
  final String? companyName;
  final String? companyAddressLine1;
  final String? companyCity;
  final String? companyState;
  final String? companyPincode;

  final int? plantId;
  final String? plantName;
  final String? plantAddressLine1;
  final String? plantCity;
  final String? plantState;
  final String? plantPincode;

  final String? parameterType;
  final String? conditionType;
  final double? threshold1;
  final double? threshold2;
  final String? importance;
  final String? statusLabel;
  final int? messageTemplateId;
  final String? templateName;
  final int isActive;
  final int status;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdByUsername;
  final String? updatedByUsername;

  Rule({
    required this.id,
    required this.name,
    this.description,
    required this.companyId,
    this.companyName,
    this.companyAddressLine1,
    this.companyCity,
    this.companyState,
    this.companyPincode,
    this.plantId,
    this.plantName,
    this.plantAddressLine1,
    this.plantCity,
    this.plantState,
    this.plantPincode,
    this.parameterType,
    this.conditionType,
    this.threshold1,
    this.threshold2,
    this.importance,
    this.statusLabel,
    this.messageTemplateId,
    this.templateName,
    required this.isActive,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.createdByUsername,
    this.updatedByUsername,
  });

  factory Rule.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String)
        return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return Rule(
      id: toInt(json['id']),
      name: json['name'] as String? ?? 'Unnamed',
      description: json['description'] as String?,
      companyId: toInt(json['company_id']),
      companyName: json['company_name'] as String?,
      companyAddressLine1: json['company_address_line_1'] as String?,
      companyCity: json['company_city'] as String?,
      companyState: json['company_state'] as String?,
      companyPincode: json['company_pincode'] as String?,
      plantId: json['plant_id'] != null ? toInt(json['plant_id']) : null,
      plantName: json['plant_name'] as String?,
      plantAddressLine1: json['plant_address_line_1'] as String?,
      plantCity: json['plant_city'] as String?,
      plantState: json['plant_state'] as String?,
      plantPincode: json['plant_pincode'] as String?,
      parameterType: json['parameter_type'] as String?,
      conditionType: json['condition_type'] as String?,
      threshold1: toDouble(json['threshold_1']),
      threshold2: toDouble(json['threshold_2']),
      importance: json['importance'] as String?,
      statusLabel: json['status_label'] as String?,
      messageTemplateId: json['message_template_id'] != null
          ? toInt(json['message_template_id'])
          : null,
      templateName: json['template_name'] as String?,
      isActive:
          (json['is_active'] as num?)?.toInt() ??
          (json['is_active'] is String
              ? (int.tryParse(json['is_active'] as String) ?? 1)
              : 1),
      status:
          (json['status'] as num?)?.toInt() ??
          (json['status'] is String
              ? (int.tryParse(json['status'] as String) ?? 1)
              : 1),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdBy: json['created_by'] != null ? toInt(json['created_by']) : null,
      updatedBy: json['updated_by'] != null ? toInt(json['updated_by']) : null,
      createdByUsername: json['created_by_username'] as String?,
      updatedByUsername: json['updated_by_username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'company_id': companyId,
      'plant_id': plantId,
      'parameter_type': parameterType,
      'condition_type': conditionType,
      'threshold_1': threshold1,
      'threshold_2': threshold2,
      'importance': importance,
      'status_label': statusLabel,
      'message_template_id': messageTemplateId,
      'is_active': isActive,
      'status': status,
    };
  }

  // Display helpers
  String get companyFullAddress {
    final parts = [
      companyAddressLine1,
      companyCity,
      companyState,
      companyPincode,
    ].whereType<String>().where((e) => e.trim().isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : '—';
  }

  String get plantFullAddress {
    final parts = [
      plantAddressLine1,
      plantCity,
      plantState,
      plantPincode,
    ].whereType<String>().where((e) => e.trim().isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : '—';
  }
}

class RuleResponse {
  final List<Rule> data;
  final Pagination pagination;

  RuleResponse({required this.data, required this.pagination});

  factory RuleResponse.fromJson(Map<String, dynamic> json) {
    return RuleResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => Rule.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String)
        return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    return Pagination(
      total: toInt(json['total']),
      page: toInt(json['page']),
      limit: toInt(json['limit']),
      totalPages: toInt(json['totalPages']),
    );
  }
}

class RuleAutocompleteInfo {
  final int id;
  final String name;
  final String? parameterType;

  RuleAutocompleteInfo({
    required this.id,
    required this.name,
    this.parameterType,
  });

  factory RuleAutocompleteInfo.fromJson(Map<String, dynamic> json) {
    return RuleAutocompleteInfo(
      id: (json['id'] is num)
          ? (json['id'] as num).toInt()
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name'] as String? ?? '',
      parameterType: json['parameter_type'] as String?,
    );
  }
}

class RuleGroup {
  final int plantId;
  final String plantName;
  final String? plantOrganizationCode;
  final String? plantAddressLine1;
  final String? plantCity;
  final String? plantState;
  final String? plantPincode;
  final List<Rule> rules;

  RuleGroup({
    required this.plantId,
    required this.plantName,
    this.plantOrganizationCode,
    this.plantAddressLine1,
    this.plantCity,
    this.plantState,
    this.plantPincode,
    required this.rules,
  });

  factory RuleGroup.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String)
        return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    return RuleGroup(
      plantId: toInt(json['plant_id']),
      plantName: json['plant_name'] as String? ?? 'Unassigned',
      plantOrganizationCode: json['plant_organization_code'] as String?,
      plantAddressLine1: json['plant_address_line_1'] as String?,
      plantCity: json['plant_city'] as String?,
      plantState: json['plant_state'] as String?,
      plantPincode: json['plant_pincode'] as String?,
      rules: (json['rules'] as List? ?? [])
          .map((i) => Rule.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  String get plantFullAddress {
    final parts = [
      plantAddressLine1,
      plantCity,
      plantState,
      plantPincode,
    ].whereType<String>().where((e) => e.trim().isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : '';
  }
}

class RuleGroupResponse {
  final List<RuleGroup> data;
  final Pagination pagination;

  RuleGroupResponse({required this.data, required this.pagination});

  factory RuleGroupResponse.fromJson(Map<String, dynamic> json) {
    return RuleGroupResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => RuleGroup.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
