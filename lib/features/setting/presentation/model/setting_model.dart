class Setting {
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
  final int? tankId;
  final String? tankNumber;
  final String? deviceId;
  final String? simNumber;
  final String? timeZone;
  final String? plantAddressLine1;
  final String? plantCity;
  final String? plantState;
  final String? plantPincode;

  final String? parameterType;
  final String? conditionType;
  final List<double?> thresholds;
  final String? importance;
  final String? statusLabel;
  final int? messageTemplateId;
  final String? templateName;
  final int? productId;
  final String? productName;
  final int isActive;
  final int status;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdByUsername;
  final String? updatedByUsername;
  final String? rosterName;
  final double? currentValue;
  final String? currentValueUnit;

  // Compatibility getters
  double? get threshold1 => thresholds.isNotEmpty ? thresholds[0] : null;
  double? get threshold2 => thresholds.length > 1 ? thresholds[1] : null;
  double? get threshold_3 => thresholds.length > 2 ? thresholds[2] : null;

  Setting({
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
    this.tankId,
    this.tankNumber,
    this.deviceId,
    this.simNumber,
    this.timeZone,
    this.plantAddressLine1,
    this.plantCity,
    this.plantState,
    this.plantPincode,
    this.parameterType,
    this.conditionType,
    required this.thresholds,
    this.importance,
    this.statusLabel,
    this.messageTemplateId,
    this.templateName,
    this.productId,
    this.productName,
    required this.isActive,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.createdByUsername,
    this.updatedByUsername,
    this.rosterName,
    this.currentValue,
    this.currentValueUnit,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
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
      try {
        // Handle cases where it might be a weird object or string
        final str = v.toString().trim();
        if (str.isEmpty || str.toLowerCase() == 'null') return null;
        // Clean up any potential non-numeric characters except '-' and '.'
        final cleanStr = str.replaceAll(RegExp(r'[^0-9.-]'), '');
        return double.tryParse(cleanStr);
      } catch (_) {
        return null;
      }
    }

    final rawParam = ((json['parameter_type'] as String?) ??
        (json['parameter_name'] as String?) ??
        (json['type'] as String?) ??
        'LEVEL');
    final normalizedParamType = rawParam.toUpperCase().trim().replaceAll(' ', '');
    final resolvedParamType = normalizedParamType == 'MFACTOR' ? 'MFACTOR' : rawParam;

    // Definite and robust mapping for thresholds from backend JSON
    final t1 = toDouble(json['threshold1'] ?? json['threshold_1'] ?? json['rule_threshold_1'] ?? json['rule_threshold1']);
    final t2 = toDouble(json['threshold2'] ?? json['threshold_2'] ?? json['rule_threshold_2'] ?? json['rule_threshold2']);
    final t3 = toDouble(json['threshold3'] ?? json['threshold_3'] ?? json['rule_threshold_3'] ?? json['rule_threshold3']);

    return Setting(
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
      tankId: json['tank_id'] != null ? toInt(json['tank_id']) : null,
      tankNumber: json['tank_number'] as String?,
      deviceId: json['device_id'] as String?,
      simNumber: json['sim_number'] as String?,
      timeZone: json['time_zone'] as String?,
      plantAddressLine1: json['plant_address_line_1'] as String?,
      plantCity: json['plant_city'] as String?,
      plantState: json['plant_state'] as String?,
      plantPincode: json['plant_pincode'] as String?,
      parameterType: resolvedParamType,
      conditionType: json['condition_type'] as String?,
      thresholds: [t1, t2, t3],
      importance: json['importance'] as String?,
      statusLabel: json['status_label'] as String?,
      messageTemplateId: json['message_template_id'] != null
          ? toInt(json['message_template_id'])
          : null,
      templateName: json['template_name'] as String?,
      productId: json['product_id'] != null ? toInt(json['product_id']) : null,
      productName: json['product_name'] as String?,
      isActive: (json['is_active'] as num?)?.toInt() ??
          (json['is_active'] is String
              ? (int.tryParse(json['is_active'] as String) ?? 1)
              : 1),
      status: (json['status'] as num?)?.toInt() ??
          (json['status'] is String
              ? (int.tryParse(json['status'] as String) ?? 1)
              : 1),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdBy: json['created_by'] != null ? toInt(json['created_by']) : null,
      updatedBy: json['updated_by'] != null ? toInt(json['updated_by']) : null,
      createdByUsername: json['created_by_username'] as String?,
      updatedByUsername: json['updated_by_username'] as String?,
      rosterName: json['roster_name'] as String?,
      currentValue: toDouble(json['current_value']),
      currentValueUnit: json['current_value_unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'company_id': companyId,
      'plant_id': plantId,
      'tank_id': tankId,
      'sim_number': simNumber,
      'time_zone': timeZone,
      'parameter_type': parameterType,
      'condition_type': conditionType,
      'thresholds': thresholds,
      // For backward compatibility with some backends
      'threshold_1': threshold1,
      'threshold_2': threshold2,
      'threshold_3': threshold_3,
      'importance': importance,
      'status_label': statusLabel,
      'message_template_id': messageTemplateId,
      'product_id': productId,
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

class SettingResponse {
  final List<Setting> data;
  final SettingPagination pagination;

  SettingResponse({required this.data, required this.pagination});

  factory SettingResponse.fromJson(Map<String, dynamic> json) {
    return SettingResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => Setting.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: SettingPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SettingPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  SettingPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory SettingPagination.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String)
        return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    return SettingPagination(
      total: toInt(json['total']),
      page: toInt(json['page']),
      limit: toInt(json['limit']),
      totalPages: toInt(json['totalPages']),
    );
  }
}

class SettingAutocompleteInfo {
  final int id;
  final String name;
  final String? plantName;
  final String? parameterType;

  SettingAutocompleteInfo({
    required this.id,
    required this.name,
    this.plantName,
    this.parameterType,
  });

  factory SettingAutocompleteInfo.fromJson(Map<String, dynamic> json) {
    return SettingAutocompleteInfo(
      id: (json['id'] is num)
          ? (json['id'] as num).toInt()
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name'] as String? ?? 'Unnamed',
      plantName: json['plant_name'] as String?,
      parameterType:
          (json['parameter_type'] as String?)?.toUpperCase().trim().replaceAll(
                ' ',
                '',
              ) ==
              'MFACTOR'
          ? 'MFACTOR'
          : (json['parameter_type'] as String?),
    );
  }
}

class SettingGroup {
  final int plantId;
  final String plantName;
  final String? plantOrganizationCode;
  final String? plantAddressLine1;
  final String? plantCity;
  final String? plantState;
  final String? plantPincode;
  final List<Setting> settings;

  SettingGroup({
    required this.plantId,
    required this.plantName,
    this.plantOrganizationCode,
    this.plantAddressLine1,
    this.plantCity,
    this.plantState,
    this.plantPincode,
    required this.settings,
  });

  factory SettingGroup.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String)
        return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    return SettingGroup(
      plantId: toInt(json['plant_id']),
      plantName: json['plant_name'] as String? ?? 'Unassigned',
      plantOrganizationCode: json['plant_organization_code'] as String?,
      plantAddressLine1: json['plant_address_line_1'] as String?,
      plantCity: json['plant_city'] as String?,
      plantState: json['plant_state'] as String?,
      plantPincode: json['plant_pincode'] as String?,
      settings: (json['rules'] as List? ?? [])
          .map((i) => Setting.fromJson(i as Map<String, dynamic>))
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

class SettingGroupResponse {
  final List<SettingGroup> data;
  final SettingPagination pagination;

  SettingGroupResponse({required this.data, required this.pagination});

  factory SettingGroupResponse.fromJson(Map<String, dynamic> json) {
    return SettingGroupResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => SettingGroup.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: SettingPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
