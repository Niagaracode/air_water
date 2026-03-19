class Roaster {
  final int id;
  final String name;
  final String? serialNumber;
  final String? model;
  final double? capacity;
  final int companyId;
  final int? plantId;
  final int? tankId;
  final int status;
  final String? companyName;
  final String? plantName;
  final String? tankNumber;

  Roaster({
    required this.id,
    required this.name,
    this.serialNumber,
    this.model,
    this.capacity,
    required this.companyId,
    this.plantId,
    this.tankId,
    this.status = 1,
    this.companyName,
    this.plantName,
    this.tankNumber,
  });

  factory Roaster.fromJson(Map<String, dynamic> json) {
    return Roaster(
      id: json['id'] as int,
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String?,
      model: json['model'] as String?,
      capacity: json['capacity'] != null ? (json['capacity'] as num).toDouble() : null,
      companyId: json['company_id'] as int,
      plantId: json['plant_id'] as int?,
      tankId: json['tank_id'] as int?,
      status: json['status'] as int? ?? 1,
      companyName: json['company_name'] as String?,
      plantName: json['plant_name'] as String?,
      tankNumber: json['tank_number'] as String?,
    );
  }
}

class RoasterParameterAssignment {
  final int? id;
  final int roasterId;
  final int? roleId;
  final int? userId;
  final String parameterName;
  final String? roleName;
  final String? username;

  RoasterParameterAssignment({
    this.id,
    required this.roasterId,
    this.roleId,
    this.userId,
    required this.parameterName,
    this.roleName,
    this.username,
  });

  factory RoasterParameterAssignment.fromJson(Map<String, dynamic> json) {
    return RoasterParameterAssignment(
      id: json['id'] as int?,
      roasterId: json['roaster_id'] as int,
      roleId: json['role_id'] as int?,
      userId: json['user_id'] as int?,
      parameterName: json['parameter_name'] as String,
      roleName: json['role_name'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'roaster_id': roasterId,
      'role_id': roleId,
      'user_id': userId,
      'parameter_name': parameterName,
    };
  }
}

class RoasterWithAssignments {
  final Roaster roaster;
  final List<RoasterParameterAssignment> assignments;

  RoasterWithAssignments({required this.roaster, required this.assignments});

  factory RoasterWithAssignments.fromJson(Map<String, dynamic> json) {
    return RoasterWithAssignments(
      roaster: Roaster.fromJson(json),
      assignments: (json['assignments'] as List?)
              ?.map((e) => RoasterParameterAssignment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RoasterResponse {
  final List<Roaster> data;
  final RoasterPagination pagination;

  RoasterResponse({required this.data, required this.pagination});

  factory RoasterResponse.fromJson(Map<String, dynamic> json) {
    return RoasterResponse(
      data: (json['data'] as List).map((i) => Roaster.fromJson(i)).toList(),
      pagination: RoasterPagination.fromJson(json['pagination']),
    );
  }
}

class RoasterPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  RoasterPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory RoasterPagination.fromJson(Map<String, dynamic> json) {
    return RoasterPagination(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
