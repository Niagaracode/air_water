class EventLog {
  final int id;
  final int? userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String action;
  final String module;
  final String? details;
  final String? ipAddress;
  final DateTime createdAt;

  EventLog({
    required this.id,
    this.userId,
    this.username,
    this.firstName,
    this.lastName,
    required this.action,
    required this.module,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  String get fullName => (firstName != null || lastName != null)
      ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
      : username ?? 'System';

  factory EventLog.fromJson(Map<String, dynamic> json) {
    return EventLog(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      action: json['action'] as String,
      module: json['module'] as String,
      details: json['details'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class EventPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  EventPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory EventPagination.fromJson(Map<String, dynamic> json) {
    return EventPagination(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class EventResponse {
  final List<EventLog> data;
  final EventPagination pagination;

  EventResponse({required this.data, required this.pagination});

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      data: (json['data'] as List).map((e) => EventLog.fromJson(e)).toList(),
      pagination: EventPagination.fromJson(json['pagination']),
    );
  }
}
