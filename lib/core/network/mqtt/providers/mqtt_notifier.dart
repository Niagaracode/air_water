// lib/core/network/mqtt/providers/mqtt_notifier.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/mqtt_connection_state.dart';
import '../models/mqtt_message.dart';
import '../mqtt_service.dart';

class MqttNotifier extends StateNotifier<MqttConnectionStateModel> {
  final MqttService _mqttService;
  final Map<String, MqttMessageModel> _lastMessages = {};
  final Map<String, Set<void Function(MqttMessageModel)>> _topicCallbacks = {};
  final Set<String> _subscribedTopics = {};

  // Maps MQTT requestId -> setting id
  //final Map<String, String> _requestToSettingId = {};

  Future<void>? _connectFuture;
  bool _isInitialized = false;

  MqttNotifier(this._mqttService) : super(const MqttConnectionStateModel(isConnected: false)) {
    _setupCallbacks();
  }

  // ==================== SETUP ====================

  void _setupCallbacks() {

    // Connection state stream
    _mqttService.connectionStateStream.listen((isConnected) {
      debugPrint('🔌 Connection state changed: $isConnected');
      state = state.copyWith(
        isConnected: isConnected,
        lastConnectedAt: isConnected ? DateTime.now() : state.lastConnectedAt,
        isConnecting: false,
        error: isConnected ? null : state.error,
      );

      if (isConnected) {
        debugPrint('✅ MQTT State: Connected');
      } else {
        debugPrint('❌ MQTT State: Disconnected');
      }
    });

    // Reconnection progress
    _mqttService.onReconnecting = (attempt, maxAttempts) {
      debugPrint('🔄 Reconnecting: $attempt/$maxAttempts');
      state = state.copyWith(
        isConnecting: true,
        error: 'Reconnecting... ($attempt/$maxAttempts)',
      );
    };

    // Error handler
    _mqttService.onError = (error) {
      debugPrint('❌ MQTT Error: $error');
      state = state.copyWith(
        error: error,
      );
    };

    // Message handler - THIS IS CRITICAL
    _mqttService.onMessageReceived = (payload, topic) {
      debugPrint('📩📩📩 MESSAGE RECEIVED IN NOTIFIER 📩📩📩');
      debugPrint('📌 Topic: $topic');
      debugPrint('📦 Payload: $payload');

      try {
        final message = MqttMessageModel.fromJson(topic, payload);
        _lastMessages[topic] = message;

        debugPrint('✅ Message parsed successfully');
        debugPrint('📊 Data: ${message.data}');

        // Notify all matching callbacks
        _notifyCallbacks(topic, message);
      } catch (e) {
        debugPrint('❌ Error parsing message: $e');
        state = state.copyWith(
          error: 'Message parse error: $e',
        );
      }
    };

    // Connection events
    _mqttService.onConnected = () {
      debugPrint('✅ MQTT Notifier: Connected');
      state = state.copyWith(error: null);
    };

    _mqttService.onDisconnected = () {
      debugPrint('❌ MQTT Notifier: Disconnected');
    };

    _mqttService.onSubscribed = (topic) {
      debugPrint('✅ MQTT Notifier: Subscribed to $topic');
    };
  }

  void _notifyCallbacks(String topic, MqttMessageModel message) {
    //debugPrint('🔍 Looking for callbacks for topic: $topic');
    //debugPrint('📋 Registered topics: ${_topicCallbacks.keys}');

    int matchedCount = 0;

    for (final entry in _topicCallbacks.entries) {
      final pattern = entry.key;
      final callbacks = entry.value;

      //debugPrint('🔎 Checking pattern: "$pattern" against "$topic"');

      if (_topicMatches(pattern, topic)) {
        //debugPrint('✅ MATCH FOUND for pattern: $pattern');
        //debugPrint('📞 Notifying ${callbacks.length} callback(s)');

        for (final callback in callbacks) {
          try {
            callback(message);
            matchedCount++;
          } catch (e) {
            debugPrint('❌ Error in callback: $e');
          }
        }
      }
    }

    debugPrint('📊 Total callbacks notified: $matchedCount');

    if (matchedCount == 0) {
      debugPrint('⚠️ No callbacks found for topic: $topic');
      debugPrint('💡 Available patterns: ${_topicCallbacks.keys.join(", ")}');
    }
  }

  bool _topicMatches(String pattern, String actualTopic) {
    // Handle special cases
    if (pattern == '#') return true;

    final patternParts = pattern.split('/');
    final topicParts = actualTopic.split('/');

    //debugPrint('🔍 Matching parts: pattern=$patternParts, topic=$topicParts');

    for (var i = 0; i < patternParts.length; i++) {
      if (patternParts[i] == '#') {
        return true; // '#' matches everything remaining
      }

      if (i >= topicParts.length) {
        debugPrint('❌ Topic shorter than pattern at index $i');
        return false;
      }

      if (patternParts[i] == '+') {
        debugPrint('➕ "+" wildcard matches "${topicParts[i]}"');
        continue; // '+' matches exactly one level
      }

      if (patternParts[i] != topicParts[i]) {
        debugPrint('❌ Mismatch: "${patternParts[i]}" vs "${topicParts[i]}"');
        return false;
      }

      debugPrint('✅ Match: "${patternParts[i]}" == "${topicParts[i]}"');
    }

    final result = patternParts.length == topicParts.length;
    debugPrint('📊 Final match result: $result');
    return result;
  }

  // ==================== CONNECTION MANAGEMENT ====================

  Future<void> initializeAndConnect() {
    if (_connectFuture != null) {
      debugPrint('⏳ Connection already in progress, reusing future');
      return _connectFuture!;
    }

    debugPrint('🚀 Starting initializeAndConnect');
    _connectFuture = _doInitializeAndConnect();
    return _connectFuture!;
  }

  Future<void> _doInitializeAndConnect() async {
    try {
      debugPrint('🔧 Initializing MQTT...');
      _isInitialized = true;
      state = state.copyWith(isConnecting: true, error: null);

      _mqttService.initialize();
      await _mqttService.connect();

      debugPrint('✅ MQTT initialization and connection complete');
    } catch (e) {
      debugPrint('❌ Failed to initialize and connect: $e');
      state = state.copyWith(
        isConnecting: false,
        error: 'Connection failed: $e',
      );
      rethrow;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> reconnectAndRestore() async {
    debugPrint('🔄 Manual reconnect requested');

    try {
      state = state.copyWith(
        isConnecting: true,
        error: null,
      );

      debugPrint('🔌 Disconnecting old connection...');
      await _mqttService.disconnect();

      debugPrint('⏳ Waiting 500ms...');
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('🔌 Reconnecting...');
      await _mqttService.connect();

      debugPrint('📡 Restoring subscriptions...');
      for (final topic in _subscribedTopics) {
        await _mqttService.subscribe(topic);
        debugPrint('✅ Restored subscription: $topic');
      }

      state = state.copyWith(isConnecting: false);
      debugPrint('✅ Reconnect completed successfully');
    } catch (e) {
      debugPrint('❌ Reconnect error: $e');
      state = state.copyWith(
        isConnecting: false,
        error: 'Reconnect failed: $e',
      );
    }
  }

  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting...');
    await _mqttService.disconnect();
    _subscribedTopics.clear();
    _connectFuture = null;
    debugPrint('✅ Disconnected');
  }

  // ==================== SUBSCRIPTION MANAGEMENT ====================

  Future<void> subscribeToTopic(String topic, {
        Function(MqttMessageModel)? onMessage,
      }) async {
    debugPrint('📡 subscribeToTopic: $topic');

    // Subscribe to broker
    if (!_subscribedTopics.contains(topic)) {
      debugPrint('📡 New topic, subscribing to broker: $topic');
      _subscribedTopics.add(topic);
      await _mqttService.subscribe(topic);
    } else {
      debugPrint('ℹ️ Already subscribed to broker: $topic');
    }

    // Add callback
    if (onMessage != null) {
      _topicCallbacks.putIfAbsent(
        topic, () => <Function(MqttMessageModel)>{},
      );
      _topicCallbacks[topic]!.add(onMessage);
      debugPrint(
          '✅ Added callback for $topic (total: ${_topicCallbacks[topic]!.length})'
      );
    }
  }

  void unsubscribeFromTopic(String topic, {
        Function(MqttMessageModel)? onMessage,
      }) {
    debugPrint('📡 unsubscribeFromTopic: $topic');

    if (!_topicCallbacks.containsKey(topic)) {
      debugPrint('⚠️ No callbacks found for $topic');
      return;
    }

    if (onMessage != null) {
      _topicCallbacks[topic]!.remove(onMessage);
      debugPrint('✅ Removed callback from $topic');
    }

    // Remove empty callback set
    if (_topicCallbacks[topic]!.isEmpty) {
      _topicCallbacks.remove(topic);
      debugPrint('🗑️ Removed empty callback set for $topic');
    }
  }

  // ==================== MESSAGE MANAGEMENT ====================

  MqttMessageModel? getLastMessage(String topic) {
    return _lastMessages[topic];
  }

  Map<String, MqttMessageModel> getAllMessages() {
    return Map.unmodifiable(_lastMessages);
  }

  // ==================== PUBLISHING ====================

  Future<void> publishMessage(String topic, Map<String, dynamic> data) async {
    debugPrint('📤 Publishing to $topic: $data');
    final message = jsonEncode(data);
    await _mqttService.publish(topic, message);
    debugPrint('✅ Published successfully');
  }

  Future<void> publishRawMessage(String topic, String message) async {
    debugPrint('📤 Publishing raw to $topic: $message');
    await _mqttService.publish(topic, message);
    debugPrint('✅ Published successfully');
  }

  // ==================== UTILITY ====================

  bool isSubscribed(String topic) {
    return _subscribedTopics.contains(topic);
  }

  bool hasCallbacks(String topic) {
    return _topicCallbacks.containsKey(topic) && _topicCallbacks[topic]!.isNotEmpty;
  }

  int getCallbackCount(String topic) {
    return _topicCallbacks[topic]?.length ?? 0;
  }

  Set<String> getSubscribedTopics() {
    return Set.unmodifiable(_subscribedTopics);
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing MQTT Notifier');
    _topicCallbacks.clear();
    _lastMessages.clear();
    _subscribedTopics.clear();
    super.dispose();
  }
}