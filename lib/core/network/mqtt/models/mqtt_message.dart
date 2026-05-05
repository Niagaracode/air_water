import 'dart:convert';

class MqttMessageModel {
  final String rawPayload;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MqttMessageModel({
    required this.rawPayload,
    required this.data,
    required this.timestamp,
  });

  factory MqttMessageModel.fromJson(String topic, String payload) {
    Map<String, dynamic> parsed = {};

    try {
      parsed = jsonDecode(payload);
    } catch (_) {
      parsed = {
        "raw": payload,
      };
    }

    return MqttMessageModel(
      rawPayload: payload,
      data: parsed,
      timestamp: DateTime.now(),
    );
  }

}