import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/mqtt_connection_state.dart';
import '../models/mqtt_message.dart';
import '../mqtt_service.dart';

class MqttNotifier extends StateNotifier<MqttConnectionStateModel> {
  final MqttService _mqttService;
  final Map<String, MqttMessageModel> _lastMessages = {};
  final Map<String, Set<Function(MqttMessageModel)>> _topicCallbacks = {};
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
      final message = MqttMessageModel.fromJson(topic, payload);
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

  Future<void> reconnectAndRestore() async {

    try {

      state = state.copyWith(
        isConnecting: true,
        error: null,
      );

      /// Disconnect old connection
      await _mqttService.disconnect();

      /// Small delay
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      /// Reconnect
      await _mqttService.connect();

      /// Restore subscriptions
      for (final topic in _subscribedTopics) {
        await _mqttService.subscribe(topic);
      }

      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
      );

      debugPrint('MQTT Manual reconnect success');

    } catch (e) {

      debugPrint('Reconnect error: $e');

      state = state.copyWith(
        isConnecting: false,
        error: e.toString(),
      );
    }
  }


  Future<void> disconnect() async {
    await _mqttService.disconnect();
    _subscribedTopics.clear();
    _isInitialized = false;
  }

  Future<void> subscribeToTopic(String topic, {
        Function(MqttMessageModel)? onMessage,
      }) async {

    if (!_subscribedTopics.contains(topic)) {
      _subscribedTopics.add(topic);
      await _mqttService.subscribe(topic);
    }

    if (onMessage != null) {
      _topicCallbacks.putIfAbsent(topic, () => <Function(MqttMessageModel)>{});
      _topicCallbacks[topic]!.add(onMessage);
    }
  }

  void unsubscribeFromTopic(
      String topic, {
        Function(MqttMessageModel)? onMessage,
      }) {

    if (_topicCallbacks.containsKey(topic) && onMessage != null) {
      _topicCallbacks[topic]!.remove(onMessage);
      if (_topicCallbacks[topic]!.isEmpty) {
        _topicCallbacks.remove(topic);
        _subscribedTopics.remove(topic);
        _mqttService.unsubscribe(topic);
      }
    }
  }

  MqttMessageModel? getLastMessage(String topic) {
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