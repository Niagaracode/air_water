class Group {
  final int id;
  final String name;
  final String? description;
  final int? companyId;
  final String? companyName;
  final int status;
  final int userCount;
  final List<int> assignedPlants;
  final List<int> assignedTanks;
  final List<String> plantNames;
  final List<String> tankNames;
  final String plantTankSummary;
  final int plantCount;
  final int tankCount;
  final String? createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.companyId,
    this.companyName,
    this.status = 1,
    this.userCount = 0,
    this.assignedPlants = const [],
    this.assignedTanks = const [],
    this.plantNames = const [],
    this.tankNames = const [],
    this.plantTankSummary = '',
    this.plantCount = 0,
    this.tankCount = 0,
    this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      status: json['status'] ?? 1,
      userCount: json['user_count'] ?? 0,
      assignedPlants: json['assigned_plants'] != null
          ? (json['assigned_plants'] as List).map((e) => e as int).toList()
          : [],
      assignedTanks: json['assigned_tanks'] != null
          ? (json['assigned_tanks'] as List).map((e) => e as int).toList()
          : [],
      plantNames: json['plant_names'] != null
          ? (json['plant_names'] as List).map((e) => e as String).toList()
          : [],
      tankNames: json['tank_names'] != null
          ? (json['tank_names'] as List).map((e) => e as String).toList()
          : [],
      plantTankSummary: json['plant_tank_summary'] as String? ?? '',
      plantCount: json['plant_count'] ?? 0,
      tankCount: json['tank_count'] ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'company_id': companyId,
      'status': status,
      'assigned_plants': assignedPlants,
      'assigned_tanks': assignedTanks,
      'plant_names': plantNames,
      'tank_names': tankNames,
      'plant_tank_summary': plantTankSummary,
      'plant_count': plantCount,
      'tank_count': tankCount,
    };
  }
}

class GroupCreateRequest {
  final String name;
  final String? description;
  final int? companyId;
  final List<int> assignedPlants;
  final List<int> assignedTanks;
  final List<int> userIds;
  final int status;

  GroupCreateRequest({
    required this.name,
    this.description,
    this.companyId,
    this.assignedPlants = const [],
    this.assignedTanks = const [],
    this.userIds = const [],
    this.status = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'company_id': companyId,
      'assigned_plants': assignedPlants,
      'assigned_tanks': assignedTanks,
      'user_ids': userIds,
      'status': status,
    };
  }
}

class GroupUser {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;

  GroupUser({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory GroupUser.fromJson(Map<String, dynamic> json) {
    return GroupUser(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
    );
  }
}

class GroupPaginatedResponse {
  final List<Group> groups;
  final int total;
  final int page;
  final int limit;

  GroupPaginatedResponse({
    required this.groups,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory GroupPaginatedResponse.fromJson(Map<String, dynamic> json) {
    return GroupPaginatedResponse(
      groups: (json['data'] as List)
          .map((i) => Group.fromJson(i as Map<String, dynamic>))
          .toList(),
      total: json['meta']['total'] as int,
      page: json['meta']['page'] as int,
      limit: json['meta']['limit'] as int,
    );
  }
}

class PlantUserCount {
  final int plantId;
  final String plantName;
  final String? plantOrganizationCode;
  final String? location;
  final int userCount;
  final int groupCount;
  final int tankCount;
  final List<String> groupNames;

  PlantUserCount({
    required this.plantId,
    required this.plantName,
    this.plantOrganizationCode,
    this.location,
    required this.userCount,
    required this.groupCount,
    required this.tankCount,
    this.groupNames = const [],
  });

  factory PlantUserCount.fromJson(Map<String, dynamic> json) {
    return PlantUserCount(
      plantId: json['plant_id'] as int,
      plantName: json['plant_name'] as String,
      plantOrganizationCode: json['plant_organization_code'] as String?,
      location: json['location'] as String?,
      userCount: json['user_count'] ?? 0,
      groupCount: json['group_count'] ?? 0,
      tankCount: json['tank_count'] ?? 0,
      groupNames: json['group_names'] != null
          ? (json['group_names'] as List).map((e) => e as String).toList()
          : [],
    );
  }
}
