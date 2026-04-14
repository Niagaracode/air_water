import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/env.dart';
import '../../../plant/presentation/model/plant_model.dart';

class Tank {
  final int tankId;
  final String tankNumber;
  final String? tankImage;
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
  final int? plantId;
  final String? plantName;
  final double? width;
  final double? height;
  final double? dishHeight;
  final double? canLength;
  final double? diameter;
  final double? length;
  final double? dishDepth;
  final double? depth;
  final double? coneLength;
  final double? tonnes;
  final int? companyId;
  final String? companyName;
  final String? deviceId;
  final String? simNumber;
  final String? timeZone;
  final int status;
  final bool? useStrappingChart;
  final List<StrappingPoint>? strappingPoints;
  final String? levelUnit;
  final String? volumeUnit;
  final String? createdAt;

  Tank({
    required this.tankId,
    required this.tankNumber,
    this.tankImage,
    this.tankTypeId,
    this.tankTypeName,
    this.unitId,
    this.unitName,
    this.productId,
    this.productName,
    this.description,
    this.latitude,
    this.longitude,
    this.plantId,
    this.plantName,
    this.width,
    this.height,
    this.dishHeight,
    this.canLength,
    this.diameter,
    this.length,
    this.dishDepth,
    this.depth,
    this.coneLength,
    this.tonnes,
    this.companyId,
    this.companyName,
    this.deviceId,
    this.simNumber,
    this.timeZone,
    required this.status,
    this.useStrappingChart,
    this.strappingPoints,
    this.levelUnit,
    this.volumeUnit,
    this.tankName,
    this.createdAt,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      tankId: _toInt(json['tank_id']) ?? 0,
      tankNumber: json['tank_number'] as String,
      tankImage: json['tank_image'] as String?,
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
      plantId: _toInt(json['plant_id']),
      plantName: json['plant_name'] as String?,
      width: _toDouble(json['width']),
      height: _toDouble(json['height']),
      dishHeight: _toDouble(json['dish_height']),
      canLength: _toDouble(json['can_length']),
      diameter: _toDouble(json['diameter']),
      length: _toDouble(json['length']),
      dishDepth: _toDouble(json['dish_depth']),
      depth: _toDouble(json['depth']),
      coneLength: _toDouble(json['cone_length']),
      tonnes: _toDouble(json['tonnes']),
      companyId: _toInt(json['company_id']),
      companyName: json['company_name'] as String?,
      deviceId: json['device_id'] as String?,
      simNumber: json['sim_number'] as String?,
      timeZone: json['time_zone'] as String?,
      status: json['status'] ?? 1,
      useStrappingChart: json['use_strapping_chart'] == 1 || json['use_strapping_chart'] == true,
      strappingPoints: (() {
        if (json['strapping_points'] != null && 
            (json['strapping_points'] as List).isNotEmpty) {
          return (json['strapping_points'] as List)
              .map((i) => StrappingPoint.fromJson(i as Map<String, dynamic>))
              .toList();
        }
        if (json['strapping_points_json'] != null && 
            json['strapping_points_json'] is String && 
            json['strapping_points_json'].toString().trim().isNotEmpty &&
            json['strapping_points_json'].toString().trim() != '[]') {
          try {
            final decoded = jsonDecode(json['strapping_points_json'].toString().trim());
            if (decoded is List) {
              return decoded
                  .map((i) => StrappingPoint.fromJson(i as Map<String, dynamic>))
                  .toList();
            }
          } catch (e) {
            return null;
          }
        }
        return null;
      })(),
      levelUnit: json['level_unit'] as String?,
      volumeUnit: json['volume_unit'] as String?,
      tankName: json['tank_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  String get statusText => status == 1 ? 'Active' : 'Inactive';

  String? get tankImageUrl {
    if (tankImage == null || tankImage!.isEmpty) return null;
    final baseUrl = Env.apiUrl.replaceAll('/api', '');
    return '$baseUrl/uploads/tank/$tankImage';
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

class TankGroup {
  final String plantName;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final int plantId;
  final String? plantOrganizationCode;
  final List<Tank> tanks;

  TankGroup({
    required this.plantName,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    required this.plantId,
    this.plantOrganizationCode,
    required this.tanks,
  });

  factory TankGroup.fromJson(Map<String, dynamic> json) {
    final tanks = (json['tanks'] as List)
        .map((i) => Tank.fromJson(i as Map<String, dynamic>))
        .toList();

    return TankGroup(
      plantName: json['plant_name'] as String,
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      plantId:
          Tank._toInt(json['plant_id']) ??
          (tanks.isNotEmpty ? (tanks.first.plantId ?? 0) : 0),
      plantOrganizationCode: json['plant_organization_code'] as String?,
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
    String? plantName,
    String? addressLine1,
    String? city,
    String? state,
    String? country,
    String? pincode,
    int? plantId,
    String? plantOrganizationCode,
    List<Tank>? tanks,
  }) {
    return TankGroup(
      plantName: plantName ?? this.plantName,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      plantId: plantId ?? this.plantId,
      plantOrganizationCode:
          plantOrganizationCode ?? this.plantOrganizationCode,
      tanks: tanks ?? this.tanks,
    );
  }
}

class TankGroupedResponse {
  final List<TankGroup> data;
  final Pagination pagination;

  TankGroupedResponse({required this.data, required this.pagination});

  factory TankGroupedResponse.fromJson(Map<String, dynamic> json) {
    return TankGroupedResponse(
      data: (json['data'] as List? ?? [])
          .map((i) => TankGroup.fromJson(i as Map<String, dynamic>))
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
  final String? tankImage;
  final XFile? imageFile;
  final int? tankTypeId;
  final int? unitId;
  final int? productId;
  final String? description;
  final double? width;
  final double? height;
  final double? dishHeight;
  final double? canLength;
  final double? diameter;
  final double? length;
  final double? dishDepth;
  final double? depth;
  final double? coneLength;
  final double? tonnes;
  final int? plantId;
  final int? status;
  final bool? useStrappingChart;
  final List<StrappingPoint>? strappingPoints;
  final String? levelUnit;
  final String? volumeUnit;

  TankCreateRequest({
    required this.tankNumber,
    this.tankImage,
    this.imageFile,
    this.tankTypeId,
    this.unitId,
    this.productId,
    this.description,
    this.width,
    this.height,
    this.dishHeight,
    this.canLength,
    this.diameter,
    this.length,
    this.dishDepth,
    this.depth,
    this.coneLength,
    this.tonnes,
    this.plantId,
    this.status,
    this.useStrappingChart,
    this.strappingPoints,
    this.levelUnit,
    this.volumeUnit,
  });

  Map<String, dynamic> toJson() {
    return {
      'tank_number': tankNumber,
      'tank_image': tankImage,
      'tank_type_id': tankTypeId,
      'unit_id': unitId,
      'product_id': productId,
      'description': description,
      'width': width,
      'height': height,
      'dish_height': dishHeight,
      'can_length': canLength,
      'diameter': diameter,
      'length': length,
      'dish_depth': dishDepth,
      'depth': depth,
      'cone_length': coneLength,
      'tonnes': tonnes,
      'plant_id': plantId,
      'status': status,
      'use_strapping_chart': useStrappingChart == true ? 1 : 0,
      'strapping_points': strappingPoints?.map((e) => e.toJson()).toList(),
      'level_unit': levelUnit,
      'volume_unit': volumeUnit,
    };
  }
}

class StrappingPoint {
  final double levelMm;
  final double volumeM3;
  final String? levelUnit;
  final String? volumeUnit;

  StrappingPoint({
    required this.levelMm,
    required this.volumeM3,
    this.levelUnit,
    this.volumeUnit,
  });

  factory StrappingPoint.fromJson(Map<String, dynamic> json) {
    return StrappingPoint(
      levelMm: _toDouble(json['level_mm'] ?? json['levelmm'] ?? json['level'] ?? 0.0),
      volumeM3: _toDouble(json['volume_m3'] ?? json['volumem3'] ?? json['volume'] ?? 0.0),
      levelUnit: (json['levelunit'] ?? json['level_unit'] ?? json['levelUnit']) as String?,
      volumeUnit: (json['volumeunit'] ?? json['volume_m3_unit'] ?? json['volumeUnit']) as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'level_mm': levelMm,
      'volume_m3': volumeM3,
      'level_unit': levelUnit,
      'volume_unit': volumeUnit,
    };
  }
}
