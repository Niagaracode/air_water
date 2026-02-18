import 'package:image_picker/image_picker.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../../core/config/app_config.dart';

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
  final int? companyId;
  final String? companyName;
  final int status;
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
    this.companyId,
    this.companyName,
    required this.status,
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
      companyId: _toInt(json['company_id']),
      companyName: json['company_name'] as String?,
      status: json['status'] ?? 1,
      tankName: json['tank_name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  String get statusText => status == 1 ? 'Active' : 'Inactive';

  String? get tankImageUrl {
    if (tankImage == null || tankImage!.isEmpty) return null;
    final baseUrl = AppConfig.apiUrl.replaceAll('/api', '');
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
      data: (json['data'] as List)
          .map((i) => TankGroup.fromJson(i as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
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
  final int? plantId;
  final int? status;

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
    this.plantId,
    this.status,
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
      'plant_id': plantId,
      'status': status,
    };
  }
}
