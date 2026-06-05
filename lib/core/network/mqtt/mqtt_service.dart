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

  // Single updates listener
  StreamSubscription? _updatesSubscription;

  // Reconnection
  Timer? _reconnectTimer;
  Timer? _connectionCheckTimer;

  int _reconnectAttempts = 0;

  static const int maxReconnectAttempts = 10;

  static const Duration reconnectDelay = Duration(seconds: 3);

  bool _isReconnecting = false;
  bool _isManualDisconnect = false;

  // Active topic list
  final Set<String> _activeSubscriptions = {};

  // Callbacks
  void Function(String payload, String topic)? onMessageReceived;
  void Function(String topic)? onSubscribed;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(int attempt, int maxAttempts)? onReconnecting;

  // Connection stream
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
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
    _client!.keepAlivePeriod = 30;
    // Manual reconnect handling
    _client!.autoReconnect = false;
    _client!.logging(on: false);
    _client!.onConnected = _handleConnected;
    _client!.onDisconnected = _handleDisconnected;
    _client!.onSubscribed = _handleSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(
      AppConstants.mqttUserName,
      AppConstants.mqttPassword,
    ).startClean().keepAliveFor(30);

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
      debugPrint(
        'Reconnection attempt $_reconnectAttempts/$maxReconnectAttempts',
      );
      onReconnecting?.call(
        _reconnectAttempts,
        maxReconnectAttempts,
      );

      try {
        _client = null;

        initialize();

        await connect();
      } catch (e) {
        debugPrint('Reconnect error: $e');
      }

      _isReconnecting = false;
    });
  }

  Future<void> _resubscribeToAllTopics() async {
    if (_activeSubscriptions.isEmpty) return;

    debugPrint(
      'Resubscribing to ${_activeSubscriptions.length} topics',
    );

    for (final topic in _activeSubscriptions) {
      await subscribe(topic);
    }
  }

  void _startConnectionChecker() {
    _connectionCheckTimer?.cancel();

    _connectionCheckTimer =
        Timer.periodic(const Duration(seconds: 20), (timer) {
          if (!isConnected &&
              !_isManualDisconnect &&
              !_isReconnecting) {
            debugPrint(
              'Connection lost. Starting reconnection...',
            );

            _attemptReconnection();
          }
        });
  }

  Future<void> subscribe(String topic) async {
    _activeSubscriptions.add(topic);
    int retries = 0;
    while (!isConnected && retries < 10) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );
      retries++;
    }

    if (!isConnected) {
      debugPrint(
        'Cannot subscribe to $topic : MQTT not connected',
      );

      return;
    }

    _client?.subscribe(
      topic,
      MqttQos.atLeastOnce,
    );

    // Create updates listener only once
    _updatesSubscription ??=
        _client?.updates?.listen(
              (
              List<MqttReceivedMessage<MqttMessage?>> messages,
              ) {
            for (final message in messages) {
              final payload =
              message.payload as MqttPublishMessage;

              final payloadString =
              MqttPublishPayload.bytesToStringAsString(
                payload.payload.message,
              );

              final receivedTopic = message.topic;

              onMessageReceived?.call(
                payloadString,
                receivedTopic,
              );
            }
          },
        );

    debugPrint('Subscribed to topic: $topic');
  }

  void unsubscribe(String topic) {
    _activeSubscriptions.remove(topic);
    if (_client == null) return;
    _client!.unsubscribe(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  Future<void> publish(
      String topic,
      String message,
      ) async {
    if (!isConnected) {
      debugPrint(
        'Cannot publish: MQTT not connected',
      );

      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      _client!.publishMessage(
        topic,
        MqttQos.exactlyOnce,
        builder.payload!,
      );

      debugPrint(
        'Published to $topic : $message',
      );
    } catch (e) {
      debugPrint('Publish error: $e');
    }
  }

  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _reconnectAttempts = 0;
    _isReconnecting = false;
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
    if (_client != null && isConnected) {
      _client!.disconnect();
    }
  }

  void _handleConnected() async {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _isManualDisconnect = false;
    _startConnectionChecker();
    _connectionStateController.add(true);
    debugPrint('MQTT Connected successfully');
    // Restore topics
    await _resubscribeToAllTopics();
    onConnected?.call();
  }

  void _handleDisconnected() {
    _connectionCheckTimer?.cancel();
    _connectionStateController.add(false);
    onDisconnected?.call();
    debugPrint('MQTT Disconnected');

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
    _updatesSubscription?.cancel();
    _connectionStateController.close();
    disconnect();
  }
}