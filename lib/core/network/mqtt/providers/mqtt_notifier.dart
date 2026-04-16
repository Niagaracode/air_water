// lib/network/mqtt/providers/mqtt_notifier.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/mqtt_connection_state.dart';
import '../models/mqtt_message.dart';
import '../mqtt_service.dart';

class MqttNotifier extends StateNotifier<MqttConnectionStateModel> {
  final MqttService _mqttService;
  final Map<String, MqttMessage> _lastMessages = {};
  final Map<String, List<Function(MqttMessage)>> _topicCallbacks = {};
  final Set<String> _subscribedTopics = {};

  bool _isInitialized = false;

  MqttNotifier(this._mqttService) : super(const MqttConnectionStateModel(isConnected: false)) {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    // Listen to connection state changes
    _mqttService.connectionStateStream.listen((isConnected) async {
      state = state.copyWith(
        isConnected: isConnected,
        lastConnectedAt: isConnected ? DateTime.now() : state.lastConnectedAt,
        isConnecting: false,
      );

      if (isConnected && _subscribedTopics.isNotEmpty) {
        debugPrint('Reconnected, resubscribing to ${_subscribedTopics.length} topics');
        await _resubscribeToTopics();
      }
    });

    // Listen to reconnection attempts
    _mqttService.onReconnecting = (attempt, maxAttempts) {
      state = state.copyWith(
        isConnecting: true,
        error: 'Reconnecting... ($attempt/$maxAttempts)',
      );
    };

    // Handle incoming messages
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
      state = state.copyWith(error: null);
    };

    _mqttService.onDisconnected = () {
      debugPrint('MQTT Notifier: Disconnected');
    };

    _mqttService.onSubscribed = (topic) {
      debugPrint('MQTT Notifier: Subscribed to $topic');
    };
  }

  Future<void> initializeAndConnect() async {
    if (_isInitialized) return;

    state = state.copyWith(isConnecting: true);
    _mqttService.initialize();
    await _mqttService.connect();
    _isInitialized = true;
  }

  Future<void> _resubscribeToTopics() async {
    for (final topic in _subscribedTopics) {
      await _mqttService.subscribe(topic);
    }
  }

  Future<void> disconnect() async {
    await _mqttService.disconnect();
    _subscribedTopics.clear();
    _isInitialized = false;
  }

  Future<void> subscribeToTopic(String topic, {Function(MqttMessage)? onMessage}) async {
    // Track subscription
    _subscribedTopics.add(topic);

    await _mqttService.subscribe(topic);

    if (onMessage != null) {
      if (!_topicCallbacks.containsKey(topic)) {
        _topicCallbacks[topic] = [];
      }
      _topicCallbacks[topic]!.add(onMessage);
    }
  }

  void unsubscribeFromTopic(String topic) {
    _subscribedTopics.remove(topic);
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

  bool isSubscribed(String topic) {
    return _subscribedTopics.contains(topic);
  }

  @override
  void dispose() {
    // Don't dispose the service, just clear callbacks
    _topicCallbacks.clear();
    _lastMessages.clear();
    super.dispose();
  }
}