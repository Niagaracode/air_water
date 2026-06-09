import '../../../site/presentation/model/site_model.dart';

class Device {
  final int id;
  final String deviceId;
  final String? notes;
  final int? siteId;
  final String? siteName;
  final int? addressId;
  final int? tankId;
  final String? tankName;
  final int? companyId;
  final String? companyName;
  final String? unitId;
  final String? unitName;
  final String? lastSync;
  final String? category;
  final String? simNumber;
  final String? powerSource;
  final int? startHour;
  final int? duration;
  final double? latitude;
  final double? longitude;
  final int status;
  final String? createdAt;
  final SiteInformation? siteInformation;

  Device({
    required this.id,
    required this.deviceId,
    this.notes,
    this.siteId,
    this.siteName,
    this.addressId,
    this.tankId,
    this.tankName,
    this.companyId,
    this.companyName,
    this.unitId,
    this.unitName,
    this.lastSync,
    this.category,
    this.simNumber,
    this.powerSource,
    this.startHour,
    this.duration,
    this.latitude,
    this.longitude,
    required this.status,
    this.createdAt,
    this.siteInformation,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      notes: json['notes'] as String?,
      siteId: json['site_id'] as int?,
      siteName: json['site_name'] as String?,
      addressId: json['address_id'] as int?,
      tankId: json['tank_id'] as int?,
      tankName: json['tank_name'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      unitId: json['unit_id']?.toString(),
      unitName: json['unit_name'] as String?,
      lastSync: json['last_sync'] as String?,
      category: json['category'] as String?,
      simNumber: json['sim_number'] as String?,
      powerSource: json['power_source'] as String?,
      startHour: json['start_hour'] as int?,
      duration: json['duration'] as int?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,

      status: json['status'] ?? 1,
      createdAt: json['created_at'] as String?,
      siteInformation: json['site_information'] != null
          ? SiteInformation.fromJson(
              json['site_information'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class SiteInformation {
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? pincode;
  final String? city;
  final String? state;
  final String? country;

  SiteInformation({
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.pincode,
    this.city,
    this.state,
    this.country,
  });

  factory SiteInformation.fromJson(Map<String, dynamic> json) {
    return SiteInformation(
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      addressLine3: json['address_line_3'] as String?,
      pincode: json['pincode'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
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

class DeviceGroup {
  final String? plantOrganizationCode;
  final String? siteName;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final List<Device> devices;

  // Alias for backward compatibility
  String? get siteOrganizationCode => plantOrganizationCode;

  String get fullAddress {
    final parts = [
      addressLine1,
      city,
      state,
      country,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  DeviceGroup({
    this.plantOrganizationCode,
    this.siteName,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    required this.devices,
  });

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    return DeviceGroup(
      plantOrganizationCode: json['plant_organization_code'] as String?,
      siteName: json['site_name'] as String?,
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      devices: (json['devices'] as List)
          .map((i) => Device.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeviceGroupedResponse {
  final List<DeviceGroup> data;
  final Pagination pagination;

  DeviceGroupedResponse({required this.data, required this.pagination});

  factory DeviceGroupedResponse.fromJson(Map<String, dynamic> json) {
    return DeviceGroupedResponse(
      data: (json['data'] as List)
          .map((i) => DeviceGroup.fromJson(i as Map<String, dynamic>))
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
      totalPages: json['total_pages'] as int,
    );
  }
}

class DeviceCreateRequest {
  final String deviceId;
  final String? notes;
  final int? siteId;
  final int? addressId;
  final int? tankId;
  final int? companyId;
  final String? unitId;
  final String? category;
  final String? simNumber;
  final String? powerSource;
  final int? startHour;
  final int? duration;
  final String? lastSync;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int? status;

  DeviceCreateRequest({
    required this.deviceId,
    this.notes,
    this.siteId,
    this.addressId,
    this.tankId,
    this.companyId,
    this.address,
    this.unitId,
    this.category,
    this.simNumber,
    this.powerSource,
    this.startHour,
    this.duration,
    this.lastSync,
    this.latitude,
    this.longitude,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'notes': notes,
      'site_id': siteId,
      'address_id': addressId,
      'tank_id': tankId,
      'company_id': companyId,
      'address': address,
      'unit_id': unitId,
      'category': category,
      'sim_number': simNumber,
      'power_source': powerSource,
      'start_hour': startHour,
      'duration': duration,
      'last_sync': lastSync,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
