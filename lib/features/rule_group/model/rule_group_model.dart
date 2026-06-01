class RuleGroupModel {

  final int id;
  final String ruleGroupName;
  final List<RuleModel> rules;

  RuleGroupModel({
    required this.id,
    required this.ruleGroupName,
    required this.rules,
  });

  factory RuleGroupModel.fromJson(Map<String, dynamic> json) {

    return RuleGroupModel(
      id: json['id'] ?? 0,
      ruleGroupName: json['rule_group_name'] ?? '',
      rules: (json['rules'] as List? ?? []).map(
            (e) => RuleModel.fromJson(e),
      ).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rule_group_name': ruleGroupName,
      'rules': rules.map((e) => e.toJson()).toList(),
    };
  }
}

class RuleModel {

  final String category;
  final List<RuleEventModel> events;
  final MissingDataModel? missingData;

  RuleModel({
    required this.category,
    required this.events,
    this.missingData,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {

    return RuleModel(
      category: json['category'] ?? '',
      events: (json['events'] as List? ?? []).map(
            (e) => RuleEventModel.fromJson(e)).toList(),
      missingData: json['missing_data'] != null
          ? MissingDataModel.fromJson(json['missing_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'events': events.map((e) => e.toJson()).toList(),
      'missing_data': missingData?.toJson(),
    };
  }
}

class RuleEventModel {

  final String description;
  final String comparator;
  final dynamic value;
  final String unit;

  RuleEventModel({
    required this.description,
    required this.comparator,
    required this.value,
    required this.unit,
  });

  factory RuleEventModel.fromJson(Map<String, dynamic> json) {

    return RuleEventModel(
      description:
      json['description'] ?? '',
      comparator: json['comparator'] ?? '',
      value: json['value'],
      unit:json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'comparator': comparator,
      'value': value,
      'unit': unit,
    };
  }
}

class MissingDataModel {

  final int hours;
  final int minutes;
  MissingDataModel({
    required this.hours,
    required this.minutes,
  });

  factory MissingDataModel.fromJson(
      Map<String, dynamic> json,
      ) {

    return MissingDataModel(
      hours: json['hours'] ?? 0,
      minutes: json['minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
    };
  }
}

class RuleGroupResponse {

  final int statusCode;
  final List<RuleGroupModel> data;
  final Pagination pagination;

  RuleGroupResponse({
    required this.statusCode,
    required this.data,
    required this.pagination,
  });

  factory RuleGroupResponse.fromJson(Map<String, dynamic> json) {

    return RuleGroupResponse(
      statusCode: json['statuscode'] ?? 0,
      data: (json['data'] as List? ?? []).map(
            (e) => RuleGroupModel.fromJson(e)).toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
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
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
