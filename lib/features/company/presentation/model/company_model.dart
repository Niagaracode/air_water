class CompanyAddress {
  final String addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String pincode;
  final String country;
  final String state;
  final String city;
  final int status;
  final int? companyId;
  final String? createdAt;

  CompanyAddress({
    required this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    required this.pincode,
    required this.country,
    required this.state,
    required this.city,
    required this.status,
    this.companyId,
    this.createdAt,
  });

  factory CompanyAddress.fromJson(Map<String, dynamic> json) {
    return CompanyAddress(
      addressLine1: json['address_line_1'] as String,
      addressLine2: json['address_line_2'] as String?,
      addressLine3: json['address_line_3'] as String?,
      pincode: json['pincode'] as String,
      country: json['country'] as String,
      state: json['state'] as String,
      city: json['city'] as String,
      status: json['status'] as int,
      companyId: json['company_id'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'address_line_3': addressLine3,
      'pincode': pincode,
      'country': country,
      'state': state,
      'city': city,
      'status': status,
      'company_id': companyId,
      'created_at': createdAt,
    };
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      city,
      state,
      country,
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyAddress &&
          runtimeType == other.runtimeType &&
          addressLine1 == other.addressLine1 &&
          pincode == other.pincode &&
          country == other.country &&
          state == other.state &&
          city == other.city &&
          companyId == other.companyId;

  @override
  int get hashCode =>
      Object.hash(addressLine1, pincode, country, state, city, companyId);
}

class Company {
  final int id;
  final String name;
  final int? createdBy;
  final String? createdAt;
  final List<CompanyAddress>? addresses;

  Company({
    required this.id,
    required this.name,
    this.createdBy,
    this.createdAt,
    this.addresses,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      createdBy: json['created_by'] as int?,
      createdAt: json['created_at'] as String?,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
                .map((i) => CompanyAddress.fromJson(i as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}

class CompanyGroup {
  final String name;
  final List<CompanyAddress> addresses;
  final String? createdAt;

  CompanyGroup({required this.name, required this.addresses, this.createdAt});

  factory CompanyGroup.fromJson(Map<String, dynamic> json) {
    return CompanyGroup(
      name: json['name'] as String,
      addresses: (json['addresses'] as List)
          .map((a) => CompanyAddress.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyGroup &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class CompanyGroupedResponse {
  final List<CompanyGroup> data;
  final Pagination pagination;

  CompanyGroupedResponse({required this.data, required this.pagination});

  factory CompanyGroupedResponse.fromJson(Map<String, dynamic> json) {
    return CompanyGroupedResponse(
      data: (json['data'] as List)
          .map((i) => CompanyGroup.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

class CompanyAutocompleteInfo {
  final int companyId;
  final String name;
  final String? organizationCode;

  CompanyAutocompleteInfo({
    required this.companyId,
    required this.name,
    this.organizationCode,
  });

  factory CompanyAutocompleteInfo.fromJson(Map<String, dynamic> json) {
    return CompanyAutocompleteInfo(
      companyId: json['id'] as int,
      name: json['name'] as String,
      organizationCode: json['organization_code'] as String?,
    );
  }
}

class CompanyCreateRequest {
  final String name;
  final int createdBy;
  final List<CompanyAddress> addresses;

  CompanyCreateRequest({
    required this.name,
    required this.createdBy,
    required this.addresses,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'created_by': createdBy,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
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
