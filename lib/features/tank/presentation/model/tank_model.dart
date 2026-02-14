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
    this.createdAt,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      tankId: json['tank_id'] as int,
      tankNumber: json['tank_number'] as String,
      tankImage: json['tank_image'] as String?,
      tankTypeId: json['tank_type_id'] as int?,
      tankTypeName: json['tank_type_name'] as String?,
      unitId: json['unit_id'] as int?,
      unitName: json['unit_name'] as String?,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] is num?)
          ? (json['latitude'] as num?)?.toDouble()
          : null,
      longitude: (json['longitude'] is num?)
          ? (json['longitude'] as num?)?.toDouble()
          : null,
      plantId: json['plant_id'] as int?,
      plantName: json['plant_name'] as String?,
      width: _toDouble(json['width']),
      height: _toDouble(json['height']),
      dishHeight: _toDouble(json['dish_height']),
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      status: json['status'] ?? 1,
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
}

class TankGroup {
  final String plantName;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final List<Tank> tanks;

  TankGroup({
    required this.plantName,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.pincode,
    required this.tanks,
  });

  factory TankGroup.fromJson(Map<String, dynamic> json) {
    return TankGroup(
      plantName: json['plant_name'] as String,
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      pincode: json['pincode'] as String?,
      tanks: (json['tanks'] as List)
          .map((i) => Tank.fromJson(i as Map<String, dynamic>))
          .toList(),
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
      productId: json['product_id'] as int,
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
    };
  }
}
