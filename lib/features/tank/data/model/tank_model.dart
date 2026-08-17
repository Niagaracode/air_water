import '../../../site/presentation/model/site_model.dart';

class Tank {
  final int tankId;
  final String tankNumber;
  final int? tankTypeId;
  final String? tankTypeName;
  final int? unitId;
  final String? unitName;
  final int? productId;
  final String? productName;
  final String? tankName;
  final String? description;
  final double? latitude;
  final double? longitude;
  final int? siteId;
  final String? siteName;
  final int? addressId;
  final double? tonnes;
  final int? companyId;
  final String? companyName;
  final String? deviceId;
  final String? deviceName;
  final String? simNumber;
  final String? timeZone;
  final int status;
  final bool? useStrappingChart;
  final List<ChannelData>? channelData;
  final int ruleId;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final int? tankDimension;
  final String? dataInterval;

  Tank({
    required this.tankId,
    required this.tankNumber,
    this.tankTypeId,
    this.tankTypeName,
    this.unitId,
    this.unitName,
    this.productId,
    this.productName,
    this.description,
    this.latitude,
    this.longitude,
    this.siteId,
    this.siteName,
    this.addressId,
    this.tonnes,
    this.companyId,
    this.companyName,
    this.deviceId,
    this.simNumber,
    this.timeZone,
    required this.status,
    this.useStrappingChart,
    this.tankName,
    this.deviceName,
    this.channelData,
    required this.ruleId,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.tankDimension,
    this.dataInterval,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      tankId: _toInt(json['tank_id']) ?? 0,
      tankNumber: json['tank_number'] as String,
      tankTypeId: _toInt(json['tank_type_id']),
      unitId: _toInt(json['unit_id']),
      tankTypeName: json['tank_type_name'] as String?,
      unitName: json['unit_name'] as String?,
      productId: _toInt(json['product_id']),
      productName: json['product_name'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] is num?)
          ? (json['latitude'] as num?)?.toDouble()
          : null,
      longitude: (json['longitude'] is num?)
          ? (json['longitude'] as num?)?.toDouble()
          : null,
      siteId: _toInt(json['plant_id']),
      siteName: json['plant_name'] as String?,
      addressId: _toInt(json['address_id']),

      tonnes: _toDouble(json['tonnes']),
      companyId: _toInt(json['company_id']),
      companyName: json['company_name'] as String?,
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      simNumber: json['sim_number'] as String?,
      timeZone: json['time_zone'] as String?,
      status: json['status'] ?? 1,
      useStrappingChart:
      json['use_strapping_chart'] == 1 ||
          json['use_strapping_chart'] == true,

      tankName: json['tank_name'] as String?,

      channelData: json['channel_data'] != null
          ? (json['channel_data'] as List)
          .map((e) => ChannelData.fromJson(e))
          .toList()
          : null,
      ruleId: json['rule_id'] ?? 0,
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      tankDimension: _toInt(json['tank_dimension']),
      dataInterval: json['data_interval'] as String?,
    );
  }

  String get statusText => status == 1 ? 'Active' : 'Inactive';

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



  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}

class ChannelData {
  final String? type;
  final double? min;
  final double? max;
  final String? units;
  final bool enabled;

  ChannelData({
    this.type,
    this.min,
    this.max,
    this.units,
    required this.enabled,
  });

  factory ChannelData.fromJson(Map<String, dynamic> json) {
    return ChannelData(
      type: json['type'] as String?,
      min: _toDouble(json['min']),
      max: _toDouble(json['max']),
      units: json['units'] as String?,
      enabled: json['enabled'] ?? false,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class TankGroup {
  final String siteName;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final int siteId;
  final String? siteOrganizationCode;
  final List<Tank> tanks;

  TankGroup({
    required this.siteName,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    required this.siteId,
    this.siteOrganizationCode,
    required this.tanks,
  });

  factory TankGroup.fromJson(Map<String, dynamic> json) {
    final tanks = (json['tanks'] as List)
        .map((i) => Tank.fromJson(i as Map<String, dynamic>))
        .toList();

    return TankGroup(
      siteName: (json['plant_name'] as String?) ?? '',
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      siteId:
          Tank._toInt(json['plant_id']) ??
          (tanks.isNotEmpty ? (tanks.first.siteId ?? 0) : 0),
      siteOrganizationCode: json['plant_organization_code'] as String?,
      tanks: tanks,
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

  TankGroup copyWith({
    String? siteName,
    String? addressLine1,
    String? city,
    String? state,
    String? country,
    String? pincode,
    int? siteId,
    String? siteOrganizationCode,
    List<Tank>? tanks,
  }) {
    return TankGroup(
      siteName: siteName ?? this.siteName,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      siteId: siteId ?? this.siteId,
      siteOrganizationCode: siteOrganizationCode ?? this.siteOrganizationCode,
      tanks: tanks ?? this.tanks,
    );
  }
}

class AssetGroupData {
  final int id;
  final String name;
  final List<Tank> tanks;

  AssetGroupData({
    required this.id,
    required this.name,
    required this.tanks,
  });

  factory AssetGroupData.fromJson(Map<String, dynamic> json) {
    return AssetGroupData(
      id: json['asset_group_id'] as int,
      name: json['asset_group_name'] as String,
      tanks: (json['tanks'] as List? ?? [])
          .map((i) => Tank.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TankGroupedResponse {
  final List<TankGroup> data;
  final List<AssetGroupData> assetGroups;
  final Pagination pagination;

  TankGroupedResponse({
    required this.data,
    required this.assetGroups,
    required this.pagination,
  });

  factory TankGroupedResponse.fromJson(Map<String, dynamic> json) {
    return TankGroupedResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => TankGroup.fromJson(i as Map<String, dynamic>))
          .toList(),
      assetGroups: (json['asset_groups'] as List? ?? [])
          .map((i) => AssetGroupData.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class TankProduct {
  final int productId;
  final String productName;

  TankProduct({required this.productId, required this.productName});

  factory TankProduct.fromJson(Map<String, dynamic> json) {
    return TankProduct(
      productId: Tank._toInt(json['product_id']) ?? 0,
      productName: json['product_name'] as String,
    );
  }
}

class TankCreateRequest {
  final String tankNumber;
  final int? unitId;
  final int? productId;
  final String? description;
  final int? siteId;
  final int? addressId;
  final String? levelUnit;
  final List<dynamic>? channelData;
  final int? companyId;
  final int? ruleId;
  final int? tankDimension;
  final String? dataInterval;

  TankCreateRequest({
    required this.tankNumber,
    this.unitId,
    this.productId,
    this.description,
    this.siteId,
    this.addressId,
    this.levelUnit,
    this.channelData,
    this.companyId,
    this.ruleId,
    this.tankDimension,
    this.dataInterval,
  });

  Map<String, dynamic> toJson() {
    return {
      'tank_number': tankNumber,
      'unit_id': unitId,
      'product_id': productId,
      'description': description,
      'plant_id': siteId,
      'address_id': addressId,
      'level_unit': levelUnit,
      'channel_data': channelData,
      'company_id': companyId,
      'rule_id': ruleId,
      'tank_dimension': tankDimension,
      'data_interval': dataInterval,
    };
  }
}