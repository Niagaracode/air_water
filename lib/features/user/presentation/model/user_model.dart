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
  final int? sessionTimeout;
  final String? createdAt;
  final List<AssignedPlant>? assignedPlants;
  final int? messageCategoryId;
  final String? messageCategoryName;

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
    this.sessionTimeout,
    this.createdAt,
    this.assignedPlants,
    this.messageCategoryId,
    this.messageCategoryName,
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
      sessionTimeout: json['session_timeout'] as int?,
      createdAt: json['created_at'] as String?,
      assignedPlants: json['assigned_plants'] != null
          ? (json['assigned_plants'] as List)
                .map((i) => AssignedPlant.fromJson(i as Map<String, dynamic>))
                .toList()
          : null,
      messageCategoryId: json['message_category_id'] as int?,
      messageCategoryName: json['message_category_name'] as String?,
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? username : parts.join(' ');
  }
}

class AssignedPlant {
  final List<int> plantIds;
  final String? plantOrganizationCode;
  final String name;
  final int count;

  AssignedPlant({
    required this.plantIds,
    this.plantOrganizationCode,
    required this.name,
    required this.count,
  });

  factory AssignedPlant.fromJson(Map<String, dynamic> json) {
    return AssignedPlant(
      plantIds: (json['plant_ids'] as List).map((e) => e as int).toList(),
      plantOrganizationCode: json['plant_organization_code'] as String?,
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
      data: (json['data'] as List)
          .map((i) => User.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
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
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
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
  final int? sessionTimeout;
  final List<int>? assignedPlants;
  final int? messageCategoryId;

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
    this.sessionTimeout,
    this.assignedPlants,
    this.messageCategoryId,
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
      'session_timeout': sessionTimeout,
      'assigned_plants': assignedPlants,
      'message_category_id': messageCategoryId,
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
}
