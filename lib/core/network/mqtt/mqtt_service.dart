// lib/core/network/mqtt/mqtt_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../../../config/app_config.dart';
import 'mqtt_client_setup.dart';

class MqttService {
  static MqttService? _instance;
  static MqttService get instance {
    _instance ??= MqttService._internal();
    return _instance!;
  }

  MqttClient? _client;
  static final String _clientId =
      'air_water_mobile_${DateTime.now().millisecondsSinceEpoch}';

  // Streams
  StreamSubscription? _updatesSubscription;
  final StreamController<bool> _connectionStateController =
  StreamController<bool>.broadcast();

  // Reconnection
  Timer? _reconnectTimer;
  Timer? _connectionCheckTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;
  static const Duration reconnectDelay = Duration(seconds: 5);
  bool _isReconnecting = false;
  bool _isManualDisconnect = false;

  // Active subscriptions
  final Set<String> _activeSubscriptions = {};

  // Callbacks
  void Function(String payload, String topic)? onMessageReceived;
  void Function(String topic)? onSubscribed;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(int attempt, int maxAttempts)? onReconnecting;
  void Function(String error)? onError;

  // Getters
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;
  bool get isConnecting => _isReconnecting || _client?.connectionStatus?.state == MqttConnectionState.connecting;
  int get reconnectAttempts => _reconnectAttempts;

  MqttService._internal();

  factory MqttService() => instance;

  // ==================== INITIALIZATION ====================

  void initialize() {
    if (_client != null) {
      debugPrint('⚠️ MQTT Service already initialized');
      return;
    }

    debugPrint('🚀 Initializing MQTT Service...');

    final mqttHost = kIsWeb
        ? AppConfig.current.mqttWebHost
        : AppConfig.current.mqttMobileHost;

    final mqttPort = kIsWeb
        ? AppConfig.current.mqttWebPort
        : AppConfig.current.mqttMobilePort;

    debugPrint('📡 MQTT Config: Host=$mqttHost, Port=$mqttPort, Secure=${AppConfig.current.mqttSecure}');

    _client = MqttClientSetup.create(
      host: mqttHost,
      port: mqttPort,
      clientId: _clientId,
      secure: AppConfig.current.mqttSecure,
    );

    _client!.port = mqttPort;
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = false;
    _client!.logging(on: true); // Enable logging

    // Set up event handlers
    _client!.onConnected = _handleConnected;
    _client!.onDisconnected = _handleDisconnected;
    _client!.onSubscribed = _handleSubscribed;
    _client!.onSubscribeFail = _handleSubscribeFail;
    // REMOVED: _client!.onPingResponseReceived - doesn't exist

    // Set connection message with authentication
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(
      AppConfig.current.mqttUserName,
      AppConfig.current.mqttPassword,
    )
        .startClean()
        .keepAliveFor(60)
        .withWillTopic('will/topic')
        .withWillMessage('$_clientId disconnected')
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    debugPrint('✅ MQTT Service initialized');
  }

  // ==================== CONNECTION ====================

  Future<void> connect() async {
    if (_client == null) {
      debugPrint('⚠️ Client not initialized, initializing...');
      initialize();
    }

    if (isConnected) {
      debugPrint('ℹ️ Already connected');
      return;
    }

    try {
      _isManualDisconnect = false;
      _isReconnecting = false;
      _reconnectAttempts = 0;

      debugPrint('🔌 Connecting to MQTT broker...');
      await _client!.connect();

      debugPrint('✅ Connection attempt completed');
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      _connectionStateController.add(false);
      onError?.call(e.toString());
      _attemptReconnection();
    }
  }

  Future<void> disconnect() async {
    debugPrint('🔌 Manual disconnect requested');
    _isManualDisconnect = true;
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _reconnectAttempts = 0;
    _isReconnecting = false;

    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    if (_client != null && isConnected) {
      try {
        _client!.disconnect();
        debugPrint('✅ Disconnected successfully');
      } catch (e) {
        debugPrint('❌ Error during disconnect: $e');
      }
    }
  }

  // ==================== RECONNECTION ====================

  void _attemptReconnection() {
    if (_isReconnecting || _isManualDisconnect) {
      debugPrint('⚠️ Reconnection already in progress or manual disconnect');
      return;
    }

    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts ($maxReconnectAttempts) reached');
      _connectionStateController.add(false);
      return;
    }

    _isReconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      _reconnectAttempts++;
      debugPrint('🔄 Reconnection attempt $_reconnectAttempts/$maxReconnectAttempts');
      onReconnecting?.call(_reconnectAttempts, maxReconnectAttempts);

      try {
        await _resetClient();
        await connect();
        _isReconnecting = false;
      } catch (e) {
        debugPrint('❌ Reconnection attempt failed: $e');
        _isReconnecting = false;
        _attemptReconnection();
      }
    });
  }

  Future<void> _resetClient() async {
    try {
      _client?.disconnect();
    } catch (_) {}

    _client = null;
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('🔄 Client reset complete');
  }

  void _startConnectionChecker() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
          (timer) {
        if (!isConnected && !_isManualDisconnect && !_isReconnecting) {
          debugPrint('⚠️ Connection lost (check). Starting reconnection...');
          _attemptReconnection();
        }
      },
    );
  }

  // ==================== SUBSCRIPTIONS ====================

  Future<void> subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) async {
    debugPrint('📡 Subscribing to: $topic');

    _activeSubscriptions.add(topic);

    // Wait for connection if not connected
    int retries = 0;
    while (!isConnected && retries < 20) {
      debugPrint('⏳ Waiting for connection... ($retries/20)');
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    if (!isConnected) {
      debugPrint('❌ Cannot subscribe to "$topic": MQTT not connected');
      onError?.call('Cannot subscribe: Not connected');
      return;
    }

    try {
      _client?.subscribe(topic, qos);
      debugPrint('✅ Subscribed to: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to $topic: $e');
      onError?.call('Subscription error: $e');
    }
  }

  void unsubscribe(String topic) {
    debugPrint('📡 Unsubscribing from: $topic');
    _activeSubscriptions.remove(topic);
    try {
      _client?.unsubscribe(topic);
      debugPrint('✅ Unsubscribed from: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing: $e');
    }
  }

  Future<void> _resubscribeToAllTopics() async {
    if (_activeSubscriptions.isEmpty) {
      debugPrint('ℹ️ No topics to resubscribe');
      return;
    }

    debugPrint('🔄 Resubscribing to ${_activeSubscriptions.length} topics...');

    for (final topic in _activeSubscriptions) {
      await subscribe(topic);
    }
  }

  // ==================== PUBLISHING ====================

  Future<void> publish(String topic, String message, {MqttQos qos = MqttQos.exactlyOnce}) async {
    if (!isConnected) {
      debugPrint('❌ Cannot publish: MQTT not connected');
      onError?.call('Cannot publish: Not connected');
      return;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      _client!.publishMessage(topic, qos, builder.payload!);
      debugPrint('📤 Published to "$topic": $message');
    } catch (e) {
      debugPrint('❌ Publish error: $e');
      onError?.call('Publish error: $e');
    }
  }

  Future<void> publishJson(String topic, Map<String, dynamic> data, {MqttQos qos = MqttQos.exactlyOnce}) async {
    final jsonString = jsonEncode(data);
    await publish(topic, jsonString, qos: qos);
  }

  // ==================== EVENT HANDLERS ====================

  void _handleConnected() {
    debugPrint('✅✅✅ MQTT CONNECTED SUCCESSFULLY ✅✅✅');

    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _isManualDisconnect = false;

    _startConnectionChecker();
    _connectionStateController.add(true);

    // Set up message listener
    _setupMessageListener();

    // Resubscribe to all topics
    _resubscribeToAllTopics();

    onConnected?.call();
  }

  void _setupMessageListener() {
    _updatesSubscription?.cancel();

    _updatesSubscription = _client?.updates?.listen(
          (List<MqttReceivedMessage<MqttMessage?>> messages) {
        debugPrint('📩📩📩 RECEIVED ${messages.length} MESSAGE(S) 📩📩📩');

        for (final message in messages) {
          try {
            final payload = message.payload as MqttPublishMessage;
            final payloadString = MqttPublishPayload.bytesToStringAsString(
              payload.payload.message,
            );

            final topic = message.topic;

            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            debugPrint('📨 TOPIC: $topic');
            debugPrint('📦 PAYLOAD: $payloadString');
            debugPrint('📏 LENGTH: ${payloadString.length} chars');
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

            // Call the callback
            onMessageReceived?.call(payloadString, topic);
          } catch (e) {
            debugPrint('❌ Error processing message: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ MQTT Updates Stream Error: $error');
        onError?.call('Stream error: $error');
      },
      onDone: () {
        debugPrint('ℹ️ MQTT Updates Stream completed');
      },
    );
  }

  void _handleDisconnected() {
    debugPrint('❌❌❌ MQTT DISCONNECTED ❌❌❌');

    _connectionCheckTimer?.cancel();
    _connectionStateController.add(false);

    _updatesSubscription?.cancel();
    _updatesSubscription = null;

    onDisconnected?.call();

    if (!_isManualDisconnect) {
      debugPrint('🔄 Unexpected disconnect. Attempting reconnection...');
      _attemptReconnection();
    }
  }

  void _handleSubscribed(String topic) {
    debugPrint('✅✅✅ SUBSCRIBED TO: $topic ✅✅✅');
    onSubscribed?.call(topic);
  }

  void _handleSubscribeFail(String topic) {
    debugPrint('❌❌❌ SUBSCRIBE FAILED FOR: $topic ❌❌❌');
    onError?.call('Subscribe failed for $topic');
  }

  // ==================== UTILITY ====================

  bool isSubscribed(String topic) {
    return _activeSubscriptions.contains(topic);
  }

  Set<String> getActiveSubscriptions() {
    return Set.unmodifiable(_activeSubscriptions);
  }

  void dispose() {
    debugPrint('🧹 Disposing MQTT Service');
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _updatesSubscription?.cancel();
    _connectionStateController.close();
    disconnect();
    _client = null;
  }
}