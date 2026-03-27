class MessageTemplate {
  final int id;
  final String name;
  final String? description;
  final String? subject;
  final String body;
  final String? dateFormat;
  final String? timeFormat;
  final String? timeZoneType;
  final String? timeZoneFixed;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final String? createdByUsername;
  final String? updatedByUsername;

  MessageTemplate({
    required this.id,
    required this.name,
    this.description,
    this.subject,
    required this.body,
    this.dateFormat,
    this.timeFormat,
    this.timeZoneType,
    this.timeZoneFixed,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.createdByUsername,
    this.updatedByUsername,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      body: json['body'] as String,
      dateFormat: json['date_format'] as String?,
      timeFormat: json['time_format'] as String?,
      timeZoneType: json['time_zone_type'] as String?,
      timeZoneFixed: json['time_zone_fixed'] as String?,
      isActive: (json['is_active'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdBy: json['created_by'] as int?,
      updatedBy: json['updated_by'] as int?,
      createdByUsername: json['created_by_username'] as String?,
      updatedByUsername: json['updated_by_username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'body': body,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'time_zone_type': timeZoneType,
      'time_zone_fixed': timeZoneFixed,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}

class MessageTemplateResponse {
  final List<MessageTemplate> data;
  final Pagination pagination;

  MessageTemplateResponse({required this.data, required this.pagination});

  factory MessageTemplateResponse.fromJson(Map<String, dynamic> json) {
    return MessageTemplateResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => MessageTemplate.fromJson(i as Map<String, dynamic>))
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
    return Pagination(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class MessageTemplateAutocompleteInfo {
  final int id;
  final String name;
  final String? description;

  MessageTemplateAutocompleteInfo({
    required this.id,
    required this.name,
    this.description,
  });

  factory MessageTemplateAutocompleteInfo.fromJson(Map<String, dynamic> json) {
    return MessageTemplateAutocompleteInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}
