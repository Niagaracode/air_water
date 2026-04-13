class Group {
  final int id;
  final String name;
  final String? description;
  final int? companyId;
  final String? companyName;
  final int status;
  final int userCount;
  final List<int> assignedSites;
  final List<int> assignedTanks;
  final List<String> siteNames;
  final List<String> tankNames;
  final String siteTankSummary;
  final int siteCount;
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
    this.assignedSites = const [],
    this.assignedTanks = const [],
    this.siteNames = const [],
    this.tankNames = const [],
    this.siteTankSummary = '',
    this.siteCount = 0,
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
      assignedSites: json['assigned_plants'] != null
          ? (json['assigned_plants'] as List).map((e) => e as int).toList()
          : [],
      assignedTanks: json['assigned_tanks'] != null
          ? (json['assigned_tanks'] as List).map((e) => e as int).toList()
          : [],
      siteNames: json['plant_names'] != null
          ? (json['plant_names'] as List).map((e) => e as String).toList()
          : [],
      tankNames: json['tank_names'] != null
          ? (json['tank_names'] as List).map((e) => e as String).toList()
          : [],
      siteTankSummary: json['plant_tank_summary'] as String? ?? '',
      siteCount: json['plant_count'] ?? 0,
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
      'assigned_plants': assignedSites,
      'assigned_tanks': assignedTanks,
      'plant_names': siteNames,
      'tank_names': tankNames,
      'plant_tank_summary': siteTankSummary,
      'plant_count': siteCount,
      'tank_count': tankCount,
    };
  }
}

class GroupCreateRequest {
  final String name;
  final String? description;
  final int? companyId;
  final List<int> assignedSites;
  final List<int> assignedTanks;
  final List<int> userIds;
  final int status;

  GroupCreateRequest({
    required this.name,
    this.description,
    this.companyId,
    this.assignedSites = const [],
    this.assignedTanks = const [],
    this.userIds = const [],
    this.status = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'company_id': companyId,
      'assigned_plants': assignedSites,
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

class SiteUserCount {
  final int siteId;
  final String siteName;
  final String? siteOrganizationCode;
  final String? location;
  final String? addressLine1;
  final String? cityName;
  final String? stateName;
  final String? pincode;
  final int userCount;
  final int groupCount;
  final int tankCount;
  final List<String> groupNames;

  SiteUserCount({
    required this.siteId,
    required this.siteName,
    this.siteOrganizationCode,
    this.location,
    this.addressLine1,
    this.cityName,
    this.stateName,
    this.pincode,
    required this.userCount,
    required this.groupCount,
    required this.tankCount,
    this.groupNames = const [],
  });

  factory SiteUserCount.fromJson(Map<String, dynamic> json) {
    return SiteUserCount(
      siteId: json['plant_id'] as int,
      siteName: json['plant_name'] as String,
      siteOrganizationCode: json['plant_organization_code'] as String?,
      location: json['location'] as String?,
      addressLine1: json['address_line_1'] as String?,
      cityName: json['city_name'] as String?,
      stateName: json['state_name'] as String?,
      pincode: json['pincode'] as String?,
      userCount: json['user_count'] ?? 0,
      groupCount: json['group_count'] ?? 0,
      tankCount: json['tank_count'] ?? 0,
      groupNames: json['group_names'] != null
          ? (json['group_names'] as List).map((e) => e as String).toList()
          : [],
    );
  }
}

class SiteDetailsDevice {
  final int id;
  final String deviceIdentifier;
  final String macAddress;
  final int tankId;

  SiteDetailsDevice({
    required this.id,
    required this.deviceIdentifier,
    required this.macAddress,
    required this.tankId,
  });

  factory SiteDetailsDevice.fromJson(Map<String, dynamic> json) {
    return SiteDetailsDevice(
      id: json['id'] as int,
      deviceIdentifier: json['device_identifier'] as String,
      macAddress: json['mac_address'] as String,
      tankId: json['tank_id'] as int,
    );
  }
}

class SiteDetailsTank {
  final int id;
  final String tankNumber;
  final num? capacity;
  final String? tankType;
  final String? product;
  final List<SiteDetailsDevice> devices;

  SiteDetailsTank({
    required this.id,
    required this.tankNumber,
    this.capacity,
    this.tankType,
    this.product,
    this.devices = const [],
  });

  factory SiteDetailsTank.fromJson(Map<String, dynamic> json) {
    return SiteDetailsTank(
      id: json['id'] as int,
      tankNumber: json['tank_number'] as String,
      capacity: json['capacity'] as num?,
      tankType: json['tank_type'] as String?,
      product: json['product'] as String?,
      devices: json['devices'] != null
          ? (json['devices'] as List)
              .map((i) => SiteDetailsDevice.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class SiteDetailsUser {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? roleName;
  final int groupId;
  final String groupName;
  final bool hasAllTanks;
  final List<int> tankIds;

  SiteDetailsUser({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.roleName,
    required this.groupId,
    required this.groupName,
    required this.hasAllTanks,
    this.tankIds = const [],
  });

  factory SiteDetailsUser.fromJson(Map<String, dynamic> json) {
    return SiteDetailsUser(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      roleName: json['role_name'] as String?,
      groupId: json['group_id'] as int,
      groupName: json['group_name'] as String,
      hasAllTanks: json['has_all_tanks'] == true,
      tankIds: json['tank_ids'] != null
          ? (json['tank_ids'] as List).map((e) => e as int).toList()
          : [],
    );
  }
}

class SiteDetailsInfo {
  final int id;
  final String name;
  final String? siteOrganizationCode;
  final String? location;
  final String? companyDetails;

  SiteDetailsInfo({
    required this.id,
    required this.name,
    this.siteOrganizationCode,
    this.location,
    this.companyDetails,
  });

  factory SiteDetailsInfo.fromJson(Map<String, dynamic> json) {
    return SiteDetailsInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      siteOrganizationCode: json['plant_organization_code'] as String?,
      location: json['location'] as String?,
      companyDetails: json['company_details'] as String?,
    );
  }
}

class SiteGroupDetails {
  final SiteDetailsInfo site;
  final List<SiteDetailsTank> tanks;
  final List<SiteDetailsUser> users;

  SiteGroupDetails({
    required this.site,
    required this.tanks,
    required this.users,
  });

  factory SiteGroupDetails.fromJson(Map<String, dynamic> json) {
    return SiteGroupDetails(
      site: SiteDetailsInfo.fromJson(json['plant'] as Map<String, dynamic>),
      tanks: json['tanks'] != null
          ? (json['tanks'] as List)
              .map((i) => SiteDetailsTank.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
      users: json['users'] != null
          ? (json['users'] as List)
              .map((i) => SiteDetailsUser.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
