import 'dart:convert';

class MqttMessage {
  final String topic;
  final String rawPayload;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MqttMessage({
    required this.topic,
    required this.rawPayload,
    required this.data,
    required this.timestamp,
  });

  factory MqttMessage.fromJson(String topic, String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      return MqttMessage(
        topic: topic,
        rawPayload: payload,
        data: data,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return MqttMessage(
        topic: topic,
        rawPayload: payload,
        data: {'error': true, 'rawMessage': payload},
        timestamp: DateTime.now(),
      );
    }
  }
}