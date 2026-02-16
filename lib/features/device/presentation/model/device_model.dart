import '../../../plant/presentation/model/plant_model.dart';

class Device {
  final int id;
  final String deviceId;
  final String? notes;
  final int? siteId;
  final String? siteName;
  final int? tankId;
  final String? tankName;
  final int? companyId;
  final String? companyName;
  final String? unitId;
  final String? unitName;
  final String? lastSync;
  final String? category;
  final String? simNumber;
  final String? timeZone;
  final int status;
  final String? createdAt;
  final SiteInformation? siteInformation;

  Device({
    required this.id,
    required this.deviceId,
    this.notes,
    this.siteId,
    this.siteName,
    this.tankId,
    this.tankName,
    this.companyId,
    this.companyName,
    this.unitId,
    this.unitName,
    this.lastSync,
    this.category,
    this.simNumber,
    this.timeZone,
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
      tankId: json['tank_id'] as int?,
      tankName: json['tank_name'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      unitId: json['unit_id']?.toString(),
      unitName: json['unit_name'] as String?,
      lastSync: json['last_sync'] as String?,
      category: json['category'] as String?,
      simNumber: json['sim_number'] as String?,
      timeZone: json['time_zone'] as String?,
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
    if (parts.isEmpty) return '';
    return parts.join(', ') + (pincode != null ? ' - $pincode' : '');
  }
}

class DeviceGroup {
  final String? plantOrganizationCode;
  final String siteName;
  final List<Device> devices;

  DeviceGroup({
    this.plantOrganizationCode,
    required this.siteName,
    required this.devices,
  });

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    return DeviceGroup(
      plantOrganizationCode: json['plant_organization_code'] as String?,
      siteName: json['site_name'] as String,
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

class DeviceCreateRequest {
  final String deviceId;
  final String? notes;
  final int? siteId;
  final int? tankId;
  final int? companyId;
  final String? unitId;
  final String? category;
  final String? simNumber;
  final String? timeZone;
  final int? status;

  DeviceCreateRequest({
    required this.deviceId,
    this.notes,
    this.siteId,
    this.tankId,
    this.companyId,
    this.unitId,
    this.category,
    this.simNumber,
    this.timeZone,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'notes': notes,
      'site_id': siteId,
      'tank_id': tankId,
      'company_id': companyId,
      'unit_id': unitId,
      'category': category,
      'sim_number': simNumber,
      'time_zone': timeZone,
      'status': status,
    };
  }
}
