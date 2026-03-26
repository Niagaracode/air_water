import 'dart:convert';

class Roster {
  final int id;
  final String description;
  final int enabled;
  final int? companyId;
  final int activeContacts;
  final int dataChannels;
  final String? roleNames;
  final String? parameterNames;
  final String? messageTemplateNames;
  final List<int> roleIds;

  Roster({
    required this.id,
    required this.description,
    required this.enabled,
    this.companyId,
    this.activeContacts = 0,
    this.dataChannels = 0,
    this.roleNames,
    this.parameterNames,
    this.messageTemplateNames,
    this.roleIds = const [],
  });

  factory Roster.fromJson(Map<String, dynamic> json) {
    return Roster(
      id: json['id'] as int,
      description: json['description'] as String,
      enabled: json['enabled'] as int? ?? 1,
      companyId: json['company_id'] as int?,
      activeContacts: json['active_contacts'] as int? ?? 0,
      dataChannels: json['data_channels'] as int? ?? 0,
      roleNames: json['role_names'] as String?,
      parameterNames: json['parameter_names'] as String?,
      messageTemplateNames: json['message_template_names'] as String?,
      roleIds: _parseRoleIds(json['role_ids']),
    );
  }

  static List<int> _parseRoleIds(dynamic roleIds) {
    if (roleIds == null) return [];
    if (roleIds is List) return roleIds.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toList();
    if (roleIds is String) {
      if (roleIds.isEmpty) return [];
      try {
        final decoded = jsonDecode(roleIds);
        if (decoded is List) return decoded.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toList();
      } catch (_) {
        // Handle comma separated if not JSON
        return roleIds.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e != 0).toList();
      }
    }
    return [];
  }
}

class RosterMember {
  final int? id;
  final int rosterId;
  final int? userId; // Nullable if role-based
  final int? roleId; // Add this
  final String? parameterName; // Add this
  final int enabled;
  final int emailNotif;
  final int emailToPhone;
  final int pushNotif;
  final int? messageTemplateId;
  
  // Joined fields
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? roleName; // For display
  final String? companyName;
  final String? messageTemplateName;
  final String? email; // Add this

  String get displayName {
    final f = (firstName == null || firstName == 'null') ? '' : firstName!;
    final l = (lastName == null || lastName == 'null') ? '' : lastName!;
    final full = '$f $l'.trim();
    if (full.isEmpty) return username ?? 'Unknown Member';
    return full;
  }

  RosterMember({
    this.id,
    required this.rosterId,
    this.userId,
    this.roleId,
    this.parameterName,
    this.enabled = 1,
    this.emailNotif = 0,
    this.emailToPhone = 0,
    this.pushNotif = 0,
    this.messageTemplateId,
    this.firstName,
    this.lastName,
    this.username,
    this.roleName,
    this.companyName,
    this.messageTemplateName,
    this.email,
  });

  factory RosterMember.fromJson(Map<String, dynamic> json) {
    return RosterMember(
      id: json['id'] as int?,
      rosterId: json['roster_id'] as int,
      userId: json['user_id'] as int?,
      roleId: json['role_id'] as int?,
      parameterName: json['parameter_name'] as String?,
      enabled: json['enabled'] as int? ?? 1,
      emailNotif: json['email_notif'] as int? ?? 0,
      emailToPhone: json['email_to_phone'] as int? ?? 0,
      pushNotif: json['push_notif'] as int? ?? 0,
      messageTemplateId: json['message_template_id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      roleName: json['role_name'] as String?,
      companyName: json['company_name'] as String?,
      messageTemplateName: json['message_template_name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'roster_id': rosterId,
      if (userId != null) 'user_id': userId,
      if (roleId != null) 'role_id': roleId,
      if (parameterName != null) 'parameter_name': parameterName,
      'enabled': enabled,
      'email_notif': emailNotif,
      'email_to_phone': emailToPhone,
      'push_notif': pushNotif,
      'message_template_id': messageTemplateId,
      if (email != null) 'email': email,
    };
  }
}

class RosterResponse {
  final List<Roster> data;
  final RosterPagination pagination;

  RosterResponse({required this.data, required this.pagination});

  factory RosterResponse.fromJson(Map<String, dynamic> json) {
    return RosterResponse(
      data: (json['data'] as List).map((i) => Roster.fromJson(i)).toList(),
      pagination: RosterPagination.fromJson(json['pagination']),
    );
  }
}

class RosterPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  RosterPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory RosterPagination.fromJson(Map<String, dynamic> json) {
    return RosterPagination(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
