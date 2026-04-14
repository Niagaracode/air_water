import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/mqtt_message.dart';
import '../models/mqtt_connection_state.dart';
import '../mqtt_service.dart';

class MqttNotifier extends StateNotifier<MqttConnectionStateModel> {
  final MqttService _mqttService;
  final Map<String, MqttMessage> _lastMessages = {};
  final Map<String, List<Function(MqttMessage)>> _topicCallbacks = {};

  MqttNotifier(this._mqttService) : super(const MqttConnectionStateModel(isConnected: false)) {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _mqttService.connectionStateStream.listen((isConnected) {
      state = state.copyWith(
        isConnected: isConnected,
        lastConnectedAt: isConnected ? DateTime.now() : state.lastConnectedAt,
        isConnecting: false,
      );
    });

    _mqttService.onMessageReceived = (payload, topic) {
      final message = MqttMessage.fromJson(topic, payload);
      _lastMessages[topic] = message;

      if (_topicCallbacks.containsKey(topic)) {
        for (var callback in _topicCallbacks[topic]!) {
          callback(message);
        }
      }
    };

    _mqttService.onConnected = () {
      debugPrint('MQTT Notifier: Connected');
    };

    _mqttService.onDisconnected = () {
      debugPrint('MQTT Notifier: Disconnected');
    };
  }

  Future<void> initializeAndConnect() async {
    state = state.copyWith(isConnecting: true);
    _mqttService.initialize();
    await _mqttService.connect();
  }

  Future<void> disconnect() async {
    await _mqttService.disconnect();
  }

  Future<void> subscribeToTopic(String topic, {Function(MqttMessage)? onMessage}) async {
    await _mqttService.subscribe(topic);

    if (onMessage != null) {
      if (!_topicCallbacks.containsKey(topic)) {
        _topicCallbacks[topic] = [];
      }
      _topicCallbacks[topic]!.add(onMessage);
    }
  }

  void unsubscribeFromTopic(String topic) {
    _mqttService.unsubscribe(topic);
    _topicCallbacks.remove(topic);
  }

  MqttMessage? getLastMessage(String topic) {
    return _lastMessages[topic];
  }

  Future<void> publishMessage(String topic, Map<String, dynamic> data) async {
    final message = jsonEncode(data);
    await _mqttService.publish(topic, message);
  }

  @override
  void dispose() {
    _mqttService.dispose();
    _topicCallbacks.clear();
    _lastMessages.clear();
    super.dispose();
  }
}