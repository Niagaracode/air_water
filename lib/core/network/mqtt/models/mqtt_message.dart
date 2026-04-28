import 'dart:convert';

class MqttMessageModel {
  final String topic;
  final String rawPayload;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MqttMessageModel({
    required this.topic,
    required this.rawPayload,
    required this.data,
    required this.timestamp,
  });

  factory MqttMessageModel.fromJson(String topic, String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      return MqttMessageModel(
        topic: topic,
        rawPayload: payload,
        data: data,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return MqttMessageModel(
        topic: topic,
        rawPayload: payload,
        data: {'error': true, 'rawMessage': payload},
        timestamp: DateTime.now(),
      );
    }
  }
}