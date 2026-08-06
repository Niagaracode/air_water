// lib/core/network/mqtt/models/mqtt_message.dart
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
      // Ensure payload is a string
      final payloadString = payload.toString();
      if (payloadString.isNotEmpty) {
        parsed = jsonDecode(payloadString);
      }
    } catch (e) {
      // If JSON parsing fails, store as raw
      parsed = {
        "raw": payload.toString(),
        "_error": e.toString(),
      };
    }

    return MqttMessageModel(
      rawPayload: payload.toString(),
      data: parsed,
      timestamp: DateTime.now(),
    );
  }

  // Add toJson for debugging
  Map<String, dynamic> toJson() {
    return {
      'rawPayload': rawPayload,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}