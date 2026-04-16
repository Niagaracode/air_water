// lib/network/mqtt/mqtt_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:uuid/uuid.dart';

import '../../config/env.dart';
import '../../constants/app_constants.dart';

class MqttService {
  static MqttService? _instance;
  static MqttService get instance {
    _instance ??= MqttService._internal();
    return _instance!;
  }

  MqttBrowserClient? _client;
  String? _currentTopic;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _subscription;

  // Reconnection properties
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;
  static const Duration reconnectDelay = Duration(seconds: 3);
  Timer? _connectionCheckTimer;
  bool _isReconnecting = false;
  bool _isManualDisconnect = false;

  // Store active subscriptions for reconnection
  final Set<String> _activeSubscriptions = {};

  // Callbacks
  void Function(String payload, String topic)? onMessageReceived;
  void Function(String topic)? onSubscribed;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(int attempt, int maxAttempts)? onReconnecting;

  // Stream controller for connection state
  final StreamController<bool> _connectionStateController = StreamController.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  MqttService._internal();

  factory MqttService() => instance;

  void initialize() {
    if (_client != null) return;

    final clientId = const Uuid().v4();

    _client = MqttBrowserClient(
      Env.mqttWebUrl,
      clientId,
    );

    _client!.websocketProtocols = ['mqtt'];
    _client!.port = AppConstants.mqttWebPort;

    // Set keep alive period to maintain connection
    _client!.keepAlivePeriod = 30;

    // Disable auto-reconnect (we'll handle it manually for better control)
    _client!.autoReconnect = false;

    _client!.logging(on: false);

    _client!.onDisconnected = _handleDisconnected;
    _client!.onConnected = _handleConnected;
    _client!.onSubscribed = _handleSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(
      AppConstants.mqttUserName,
      AppConstants.mqttPassword,
    ).startClean()
        .keepAliveFor(30);

    _client!.connectionMessage = connMessage;
  }

  Future<void> connect() async {
    if (_client == null || isConnected) return;

    try {
      _isManualDisconnect = false;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT Connection error: $e');
      _connectionStateController.add(false);
      _attemptReconnection();
    }
  }

  void _attemptReconnection() {
    if (_isReconnecting || _isManualDisconnect) return;
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }

    _isReconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      _reconnectAttempts++;
      debugPrint('Reconnection attempt $_reconnectAttempts/$maxReconnectAttempts');
      onReconnecting?.call(_reconnectAttempts, maxReconnectAttempts);

      if (!isConnected && !_isManualDisconnect) {
        // Re-initialize and connect
        _client = null;
        initialize();
        await connect();

        if (isConnected) {
          _reconnectAttempts = 0;
          await _resubscribeToAllTopics();
        }
      }
      _isReconnecting = false;
    });
  }

  Future<void> _resubscribeToAllTopics() async {
    if (_activeSubscriptions.isEmpty) return;

    debugPrint('Resubscribing to ${_activeSubscriptions.length} topics');
    for (final topic in _activeSubscriptions) {
      await subscribe(topic);
    }
  }

  void _startConnectionChecker() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!isConnected && !_isManualDisconnect && !_isReconnecting) {
        debugPrint('Connection check: Not connected, attempting reconnection');
        _attemptReconnection();
      }
    });
  }

  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _reconnectAttempts = 0;
    _isReconnecting = false;

    if (_client == null) return;
    if (isConnected) {
      _client!.disconnect();
    }
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> subscribe(String topic) async {
    // Store topic for reconnection
    _activeSubscriptions.add(topic);

    int retries = 0;
    while (!isConnected && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    if (!isConnected) {
      debugPrint('Cannot subscribe to $topic: MQTT not connected');
      return;
    }

    // Cancel previous subscription if changing topics
    if (_currentTopic != null && _currentTopic != topic) {
      _client?.unsubscribe(_currentTopic!);
      await _subscription?.cancel();
    }

    // Subscribe to new topic
    _client?.subscribe(topic, MqttQos.atLeastOnce);
    _currentTopic = topic;

    // Set up message listener
    _subscription?.cancel();
    _subscription = _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage?>> messages) {
      if (messages.isNotEmpty) {
        final MqttReceivedMessage<MqttMessage?> message = messages[0];
        final MqttPublishMessage payload = message.payload as MqttPublishMessage;
        final String payloadString = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message
        );

        // Call the callback with the topic from the message
        final receivedTopic = message.topic;
        onMessageReceived?.call(payloadString, receivedTopic);
      }
    });

    debugPrint('Subscribed to topic: $topic');
  }

  void unsubscribe(String topic) {
    _activeSubscriptions.remove(topic);

    if (_client == null) return;

    if (_currentTopic == topic) {
      _subscription?.cancel();
      _subscription = null;
      _client!.unsubscribe(topic);
      _currentTopic = null;
    } else {
      _client!.unsubscribe(topic);
    }

    debugPrint('Unsubscribed from topic: $topic');
  }

  Future<void> publish(String topic, String message) async {
    if (!isConnected) {
      debugPrint('Cannot publish: MQTT not connected');
      return;
    }

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
      debugPrint('Published to $topic: $message');
    } catch (e) {
      debugPrint('Publish error: $e');
    }
  }

  void _handleConnected() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _isManualDisconnect = false;
    _startConnectionChecker();
    _connectionStateController.add(true);
    onConnected?.call();
    debugPrint('MQTT Connected successfully');
  }

  void _handleDisconnected() {
    _connectionCheckTimer?.cancel();
    _connectionStateController.add(false);
    onDisconnected?.call();
    debugPrint('MQTT Disconnected');

    // Attempt reconnection if not manually disconnected
    if (!_isManualDisconnect) {
      _attemptReconnection();
    }
  }

  void _handleSubscribed(String topic) {
    debugPrint('MQTT Subscribed to: $topic');
    onSubscribed?.call(topic);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _subscription?.cancel();
    _connectionStateController.close();
    disconnect();
  }
}