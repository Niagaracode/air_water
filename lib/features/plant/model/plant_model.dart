class Plant {
  final int id;
  final String name;
  final String? plantOrganizationCode;
  final int status;
  final int? companyId;
  final String? companyName;
  final String? countryName;
  final String? stateName;
  final String? cityName;
  final String? createdAt;

  Plant({
    required this.id,
    required this.name,
    this.plantOrganizationCode,
    required this.status,
    this.companyId,
    this.companyName,
    this.countryName,
    this.stateName,
    this.cityName,
    this.createdAt,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as int,
      name: json['name'] as String,
      plantOrganizationCode: json['plant_organization_code'] as String?,
      status: json['status'] as int,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      countryName: json['country_name'] as String?,
      stateName: json['state_name'] as String?,
      cityName: json['city_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plant_organization_code': plantOrganizationCode,
      'status': status,
      'company_id': companyId,
      'company_name': companyName,
      'country_name': countryName,
      'state_name': stateName,
      'city_name': cityName,
      'created_at': createdAt,
    };
  }

  String get statusText => status == 1 ? 'Active' : 'Inactive';

  String get fullAddress {
    final parts = [
      cityName,
      stateName,
      countryName,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class PlantResponse {
  final List<Plant> data;
  final Pagination pagination;

  PlantResponse({required this.data, required this.pagination});

  factory PlantResponse.fromJson(Map<String, dynamic> json) {
    return PlantResponse(
      data: (json['data'] as List)
          .map((i) => Plant.fromJson(i as Map<String, dynamic>))
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

class PlantLocation {
  final String address;
  final String pinCode;
  final String country;
  final String state;
  final String city;

  PlantLocation({
    required this.address,
    required this.pinCode,
    required this.country,
    required this.state,
    required this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'pin_code': pinCode,
      'country': country,
      'state': state,
      'city': city,
    };
  }
}

class PlantCreateRequest {
  final String name;
  final String companyName;
  final List<PlantLocation> locations;
  final int status;

  PlantCreateRequest({
    required this.name,
    required this.companyName,
    required this.locations,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'company_name': companyName,
      'locations': locations.map((l) => l.toJson()).toList(),
      'status': status,
    };
  }
}
