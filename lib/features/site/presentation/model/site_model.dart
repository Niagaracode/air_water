import '../../../company/presentation/model/company_model.dart';

class Site {
  final int id;
  final String name;
  final String? siteOrganizationCode;
  final int status;
  final int? companyId;
  final String? companyName;
  final String? countryName;
  final String? stateName;
  final String? cityName;
  final String? contactNumber;
  final String? createdAt;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? pincode;
  final String? companyCountry;
  final String? companyState;
  final String? companyCity;
  final String? companyAddressLine1;
  final String? companyPincode;
  final String? timeZone;

  Site({
    required this.id,
    required this.name,
    this.siteOrganizationCode,
    required this.status,
    this.companyId,
    this.companyName,
    this.countryName,
    this.stateName,
    this.cityName,
    this.contactNumber,
    this.createdAt,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.pincode,
    this.companyCountry,
    this.companyState,
    this.companyCity,
    this.companyAddressLine1,
    this.companyPincode,
    this.timeZone,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as int,
      name: json['name'] as String,
      siteOrganizationCode: json['plant_organization_code'] as String?,
      status: json['status'] as int,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      countryName: json['country_name'] as String?,
      stateName: json['state_name'] as String?,
      cityName: json['city_name'] as String?,
      contactNumber: json['contact_number'] as String?,
      createdAt: json['created_at'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      addressLine3: json['address_line_3'] as String?,
      pincode: json['pincode'] as String?,
      companyCountry: json['company_country'] as String?,
      companyState: json['company_state'] as String?,
      companyCity: json['company_city'] as String?,
      companyAddressLine1: json['company_address_line_1'] as String?,
      companyPincode: json['company_pincode'] as String?,
      timeZone: json['time_zone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plant_organization_code': siteOrganizationCode,
      'status': status,
      'company_id': companyId,
      'company_name': companyName,
      'country_name': countryName,
      'state_name': stateName,
      'city_name': cityName,
      'created_at': createdAt,
      'time_zone': timeZone,
    };
  }

  String get statusText => status == 1 ? 'Active' : 'Inactive';

  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      addressLine3,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  String get companyFullAddress {
    final locParts = [
      companyCity,
      companyState,
      companyCountry,
    ].where((p) => p != null && p.isNotEmpty).toList();

    final locString = locParts.join(', ');
    final pinSuffix = (companyPincode != null && companyPincode!.isNotEmpty)
        ? ' - $companyPincode'
        : '';

    final addressLine = companyAddressLine1 ?? '';

    return (addressLine.isNotEmpty && locString.isNotEmpty)
        ? '$addressLine, $locString$pinSuffix'
        : (addressLine.isNotEmpty
              ? '$addressLine$pinSuffix'
              : '$locString$pinSuffix');
  }

  String get siteLocation {
    final parts = [
      cityName,
      stateName,
      countryName,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class SiteResponse {
  final List<Site> data;
  final Pagination pagination;

  SiteResponse({required this.data, required this.pagination});

  factory SiteResponse.fromJson(Map<String, dynamic> json) {
    return SiteResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => Site.fromJson(i as Map<String, dynamic>))
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

class SiteLocation {
  final String address;
  final String pinCode;
  final String country;
  final String state;
  final String city;
  final String? timeZone;

  SiteLocation({
    required this.address,
    required this.pinCode,
    required this.country,
    required this.state,
    required this.city,
    this.timeZone,
  });


  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'pin_code': pinCode,
      'country': country,
      'state': state,
      'city': city,
      'time_zone': timeZone,
    };

  }
}

class SiteGroupAddress {
  final int? siteId;
  final String? siteName;
  final String? city;
  final String? state;
  final String? country;
  final String? contactNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? pincode;
  final int? companyId;
  final String? companyName;
  final String? companyAddressLine1;
  final String? companyCity;
  final String? companyState;
  final String? companyCountry;
  final String? companyPincode;
  final String? timeZone;
  final int? status;
  final String? createdAt;

  SiteGroupAddress({
    this.siteId,
    this.siteName,
    this.city,
    this.state,
    this.country,
    this.contactNumber,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.pincode,
    this.companyId,
    this.companyName,
    this.companyAddressLine1,
    this.companyCity,
    this.companyState,
    this.companyCountry,
    this.companyPincode,
    this.timeZone,
    this.status,
    this.createdAt,
  });

  factory SiteGroupAddress.fromJson(Map<String, dynamic> json) {
    return SiteGroupAddress(
      siteId: json['plant_id'] as int?,
      siteName: json['plant_name'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      contactNumber: json['contact_number'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      addressLine3: json['address_line_3'] as String?,
      pincode: json['pincode'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      companyAddressLine1: json['company_address_line_1'] as String?,
      companyCity: json['company_city'] as String?,
      companyState: json['company_state'] as String?,
      companyCountry: json['company_country'] as String?,
      companyPincode: json['company_pincode'] as String?,
      timeZone: json['time_zone'] as String?,
      status: json['status'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  String get statusText => status == 1 ? 'Active' : 'Inactive';

  String get siteLocation {
    final parts = [
      city,
      state,
      country,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get companyFullAddress {
    final locParts = [
      companyCity,
      companyState,
      companyCountry,
    ].where((p) => p != null && p.isNotEmpty).toList();

    final locString = locParts.join(', ');
    final pinSuffix = (companyPincode != null && companyPincode!.isNotEmpty)
        ? ' - $companyPincode'
        : '';

    final addressLine = companyAddressLine1 ?? '';

    return (addressLine.isNotEmpty && locString.isNotEmpty)
        ? '$addressLine, $locString$pinSuffix'
        : (addressLine.isNotEmpty
              ? '$addressLine$pinSuffix'
              : '$locString$pinSuffix');
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      addressLine3,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  Site toSite() {
    return Site(
      id: siteId ?? 0,
      name: siteName ?? '',
      status: status ?? 1,
      companyId: companyId,
      companyName: companyName,
      countryName: country,
      stateName: state,
      cityName: city,
      contactNumber: contactNumber,
      createdAt: createdAt,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      addressLine3: addressLine3,
      pincode: pincode,
      companyCountry: companyCountry,
      companyState: companyState,
      companyCity: companyCity,
      companyAddressLine1: companyAddressLine1,
      companyPincode: companyPincode,
      timeZone: timeZone,
    );
  }
}

class SiteGroup {
  final String? siteOrganizationCode;
  final String name;
  final String? timeZone;
  final String? createdAt;
  final List<SiteGroupAddress> addresses;

  SiteGroup({
    this.siteOrganizationCode,
    required this.name,
    this.timeZone,
    this.createdAt,
    required this.addresses,
  });

  factory SiteGroup.fromJson(Map<String, dynamic> json) {
    return SiteGroup(
      siteOrganizationCode: json['plant_organization_code'] as String?,
      name: json['name'] as String,
      timeZone: json['time_zone'] as String?,
      createdAt: json['created_at'] as String?,
      addresses: (json['addresses'] as List)
          .map((a) => SiteGroupAddress.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SiteGroupedResponse {
  final List<SiteGroup> data;
  final Pagination pagination;

  SiteGroupedResponse({required this.data, required this.pagination});

  factory SiteGroupedResponse.fromJson(Map<String, dynamic> json) {
    return SiteGroupedResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => SiteGroup.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SiteCreateRequest {
  final String name;
  final String orgCode;
  final int companyId;
  final String? country;
  final String? state;
  final String? city;
  final String? timeZone;
  final List<CompanyAddress> addresses;

  SiteCreateRequest({
    required this.name,
    required this.orgCode,
    required this.companyId,
    this.country,
    this.state,
    this.city,
    this.timeZone,
    required this.addresses,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'plant_organization_code': orgCode,
      'company_id': companyId,
      'country': country,
      'state': state,
      'city': city,
      'time_zone': timeZone,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }
}

class SiteAutocompleteInfo {
  final int siteId;
  final String siteName;
  final int? companyId;
  final String? companyName;
  final String? displayName;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? contactNumber;
  final String? pincode;
  final String? timeZone;

  SiteAutocompleteInfo({
    required this.siteId,
    required this.siteName,
    this.companyId,
    this.companyName,
    this.displayName,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.contactNumber,
    this.pincode,
    this.timeZone,
  });

  factory SiteAutocompleteInfo.fromJson(Map<String, dynamic> json) {
    return SiteAutocompleteInfo(
      siteId: json['plant_id'] as int,
      siteName: json['plant_name'] as String,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      displayName: json['display_name'] as String?,
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      contactNumber: json['contact_number'] as String?,
      pincode: json['pincode'] as String?,
      timeZone: json['time_zone'] as String?,
    );
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      city,
      state,
      country,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}
