import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:uuid/uuid.dart';
import '../../config/env.dart';
import '../../constants/app_constants.dart';

class MqttService {
  static MqttService? _instance;
  MqttClient? _client;
  String? _currentTopic;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _subscription;

  // Callbacks
  void Function(String payload, String topic)? onMessageReceived;
  void Function(String topic)? onSubscribed;
  void Function()? onConnected;
  void Function()? onDisconnected;

  // Stream controller for connection state
  final StreamController<bool> _connectionStateController = StreamController.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;

  MqttService._internal();

  factory MqttService() {
    _instance ??= MqttService._internal();
    return _instance!;
  }

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
    _client!.logging(on: false);

    _client!.onDisconnected = _handleDisconnected;
    _client!.onConnected = _handleConnected;
    _client!.onSubscribed = _handleSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(
      AppConstants.mqttUserName,
      AppConstants.mqttPassword,
    ).startClean();

    _client!.connectionMessage = connMessage;
  }

  Future<void> connect() async {
    if (_client == null || isConnected) return;

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT Connection error: $e');
      _connectionStateController.add(false);
    }
  }

  Future<void> disconnect() async {
    if (_client == null) return;
    if (isConnected) {
      _client!.disconnect();
    }
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> subscribe(String topic) async {
    int retries = 0;
    while (!isConnected && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    if (!isConnected) {
      debugPrint('Cannot subscribe: MQTT not connected');
      return;
    }

    if (_currentTopic != null && _currentTopic != topic) {
      _client?.unsubscribe(_currentTopic!);
    }

    await _subscription?.cancel();

    _client?.subscribe(topic, MqttQos.atLeastOnce);
    _currentTopic = topic;

    _subscription = _client?.updates?.listen((messages) {
      if (messages.isNotEmpty) {
        final message = messages[0];
        final payload = message.payload as MqttPublishMessage;
        final payloadString = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message
        );
        onMessageReceived?.call(payloadString, topic);
      }
    });
  }

  void unsubscribe(String topic) {
    if (_client == null) return;
    _subscription?.cancel();
    _subscription = null;

    if (_currentTopic == topic) {
      _client!.unsubscribe(topic);
      _currentTopic = null;
    } else {
      _client!.unsubscribe(topic);
    }
  }

  Future<void> publish(String topic, String message) async {
    if (!isConnected) {
      debugPrint('Cannot publish: MQTT not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    } catch (e) {
      debugPrint('Publish error: $e');
    }
  }

  void _handleConnected() {
    _connectionStateController.add(true);
    onConnected?.call();
  }

  void _handleDisconnected() {
    _connectionStateController.add(false);
    onDisconnected?.call();
  }

  void _handleSubscribed(String topic) {
    debugPrint('Subscribed to: $topic');
    onSubscribed?.call(topic);
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStateController.close();
    disconnect();
  }
}