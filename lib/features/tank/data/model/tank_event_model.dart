import '../../../../shared/utils/app_helper.dart';

class TankEventModel {

  final String type;
  final String value;
  final String message;
  final String status;
  final DateTime createdAt;

  TankEventModel({

    required this.type,
    required this.value,
    required this.message,
    required this.status,
    required this.createdAt,

  });

  factory TankEventModel.fromJson(Map<String, dynamic> json) {
    return TankEventModel(
      type: json['type'] ?? '',
      value: json['value']?.toString() ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      createdAt: parseDateTime(json['created_at']),
    );
  }
}