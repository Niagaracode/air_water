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
    };
  }
}

class GroupCreateRequest {
  final String name;
  final String? description;
  final int? companyId;
  final List<int> assignedPlants;
  final List<int> assignedTanks;
  final int status;

  GroupCreateRequest({
    required this.name,
    this.description,
    this.companyId,
    this.assignedPlants = const [],
    this.assignedTanks = const [],
    this.status = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'company_id': companyId,
      'assigned_plants': assignedPlants,
      'assigned_tanks': assignedTanks,
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
