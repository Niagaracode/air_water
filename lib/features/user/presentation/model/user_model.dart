class User {
  final int userId;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final int? roleId;
  final String? roleName;
  final int? companyId;
  final String? companyName;
  final String? mobileNumber;
  final int status;
  final int? sessionHours;
  final int? sessionMinutes;
  final String? createdAt;

  final List<AssignedSite>? assignedSites;
  final List<int>? assignedTanks;
  final int? messageCategoryId;
  final String? messageCategoryName;
  final List<String>? rosters;
  final List<String>? groupNames;
  final int? rosterGroupId; // Added this

  User({
    required this.userId,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.roleId,
    this.roleName,
    this.companyId,
    this.companyName,
    this.mobileNumber,
    required this.status,
    this.sessionHours,
    this.sessionMinutes,
    this.createdAt,

    this.assignedSites,
    this.assignedTanks,
    this.messageCategoryId,
    this.messageCategoryName,
    this.rosters,
    this.groupNames,
    this.rosterGroupId, // Added this
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      roleId: json['role_id'] as int?,
      roleName: json['role_name'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      status: json['status'] ?? 1,
      sessionHours: json['session_hours'] as int?,
      sessionMinutes: json['session_minutes'] as int?,
      createdAt: json['created_at'] as String?,
      assignedSites: json['assigned_plants'] != null
          ? (json['assigned_plants'] as List)
                .map((i) => AssignedSite.fromJson(i as Map<String, dynamic>))
                .toList()
          : null,
      assignedTanks: json['assigned_tanks'] != null
          ? (json['assigned_tanks'] as List).map((e) => e as int).toList()
          : null,
      messageCategoryId: json['message_category_id'] as int?,
      messageCategoryName: json['message_category_name'] as String?,
      rosters: json['rosters'] != null
          ? (json['rosters'] as List).map((e) => e as String).toList()
          : null,
      groupNames: json['group_names'] != null
          ? (json['group_names'] as List).map((e) => e as String).toList()
          : null,
      rosterGroupId: json['roster_group_id'] as int?, // Added this
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? username : parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

class AssignedSite {
  final List<int> siteIds;
  final String? siteOrganizationCode;
  final String name;
  final int count;

  AssignedSite({
    required this.siteIds,
    this.siteOrganizationCode,
    required this.name,
    required this.count,
  });

  factory AssignedSite.fromJson(Map<String, dynamic> json) {
    return AssignedSite(
      siteIds: (json['plant_ids'] as List).map((e) => e as int).toList(),
      siteOrganizationCode: json['plant_organization_code'] as String?,
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class UserSearchResponse {
  final List<User> data;
  final Pagination pagination;

  UserSearchResponse({required this.data, required this.pagination});

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => User.fromJson(i as Map<String, dynamic>))
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

class UserCreateRequest {
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? password;
  final int? roleId;
  final int? companyId;
  final String? mobileNumber;
  final int? status;
  final int? sessionHours;
  final int? sessionMinutes;
  final List<int>? assignedSites;
  final List<int>? assignedTanks;
  final int? messageCategoryId;
  final int? rosterGroupId; // Added this

  UserCreateRequest({
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.password,
    this.roleId,
    this.companyId,
    this.mobileNumber,
    this.status,
    this.sessionHours,
    this.sessionMinutes,
    this.assignedSites,
    this.assignedTanks,
    this.messageCategoryId,
    this.rosterGroupId, // Added this
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      if (password != null) 'password': password,
      'role_id': roleId,
      'company_id': companyId,
      'mobile_number': mobileNumber,
      'status': status,
      'session_hours': sessionHours,
      'session_minutes': sessionMinutes,
      'assigned_plants': assignedSites,
      'assigned_tanks': assignedTanks,
      'message_category_id': messageCategoryId,
      if (rosterGroupId != null) 'roster_group_id': rosterGroupId, // Added this
    };
  }
}

class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'] as int, name: json['name'] as String);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CompanyAutocomplete {
  final int id;
  final String name;

  CompanyAutocomplete({required this.id, required this.name});

  factory CompanyAutocomplete.fromJson(Map<String, dynamic> json) {
    return CompanyAutocomplete(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAutocomplete &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// SiteTankAssignment class for the dropdown selector widget
// This is used internally by the widget and converted to assignedSites/assignedTanks
class SiteTankAssignment {
  final int siteId;
  final String siteName;
  final bool allTanks;
  final List<int>? tankIds;
  final List<String>? tankNames;

  SiteTankAssignment({
    required this.siteId,
    required this.siteName,
    required this.allTanks,
    this.tankIds,
    this.tankNames,
  });

  String get displayText {
    if (allTanks) {
      return '$siteName (All Tanks)';
    } else if (tankIds != null) {
      return '$siteName (${tankIds!.length} tanks)';
    }
    return siteName;
  }

  Map<String, dynamic> toJson() {
    return {
      'plant_id': siteId,
      'plant_name': siteName,
      'all_tanks': allTanks,
      if (!allTanks && tankIds != null) 'tank_ids': tankIds,
    };
  }

  factory SiteTankAssignment.fromJson(Map<String, dynamic> json) {
    return SiteTankAssignment(
      siteId: json['plant_id'] as int,
      siteName: json['plant_name'] as String? ?? '',
      allTanks: json['all_tanks'] as bool? ?? false,
      tankIds: json['tank_ids'] != null
          ? (json['tank_ids'] as List).map((e) => e as int).toList()
          : null,
      tankNames: json['tank_names'] != null
          ? (json['tank_names'] as List).map((e) => e as String).toList()
          : null,
    );
  }
}
