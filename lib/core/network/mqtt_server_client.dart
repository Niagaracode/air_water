import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:uuid/uuid.dart';
import '../config/env.dart';
import '../constants/app_constants.dart';

class MqttServerClient {
  static MqttServerClient? _instance;
  //MqttPayloadProvider? providerState;
  MqttClient? _client;
  String? currentTopic;

  MqttServerClient._internal();

  factory MqttServerClient() {
    _instance ??= MqttServerClient._internal();
    return _instance!;
  }

  // Connection State
  bool get isConnected => _client?.connectionStatus?.state == MqttConnectionState.connected;
  MqttConnectionState get mqttConnectionState => _client?.connectionStatus?.state ?? MqttConnectionState.disconnected;

  final StreamController<MqttConnectionState> _connectionController = StreamController.broadcast();
  Stream<MqttConnectionState> get mqttConnectionStream => _connectionController.stream;

  StreamSubscription? _subscription;


  void initializeMQTTClient() {
    //providerState = state;
    final uniqueId = const Uuid().v4();

    if (_client != null) return;

    _client = MqttBrowserClient(
      Env.mqttWebUrl,
      uniqueId,
    );
    _client!.websocketProtocols = ['mqtt'];
    _client!.port = AppConstants.mqttWebPort;

    _client!
      ..keepAlivePeriod = 30
      ..logging(on: false)
      ..onDisconnected = onDisconnected
      ..onConnected = onConnected
      ..onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(uniqueId)
        .authenticateAs(
      AppConstants.mqttUserName,
      AppConstants.mqttPassword,
    ).startClean();

    _client!.connectionMessage = connMess;
  }

  Future<void> connect() async {
    if (_client == null ||
        isConnected ||
        _client!.connectionStatus?.state == MqttConnectionState.connecting) {
      return;
    }

    try {
      await _client!.connect();
    } catch (e, stackTrace) {
      debugPrint('MQTT Connect Exception: $e');
      debugPrint('$stackTrace');
      _client?.disconnect();
    }
  }

  Future<void> disConnect() async {
    assert(_client != null);
    if (isConnected) {
      try {
        _client!.disconnect();
      } catch (e, stackTrace) {
        debugPrint('MQTT Disconnect Exception: $e');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> topicToSubscribe(String topic) async {
    try {
      int retries = 0;
      while ((_client?.connectionStatus?.state != MqttConnectionState.connected) &&
          retries < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }

      if (_client?.connectionStatus?.state !=
          MqttConnectionState.connected) {
        debugPrint('MQTT not connected. Cannot subscribe to topic: $topic');
        return;
      }

      // Unsubscribe previous topic safely
      if (currentTopic != null && currentTopic != topic) {
        _client?.unsubscribe(currentTopic!);
      }

      await _subscription?.cancel();

      _client?.subscribe(topic, MqttQos.atLeastOnce);
      currentTopic = topic;

      _subscription = _client?.updates?.listen(
            (List<MqttReceivedMessage<MqttMessage?>>? c) {
          if (c != null && c.isNotEmpty) {
            final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
            final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
            onMqttPayloadReceived(pt);
          }
        },
      );

      debugPrint("Subscribed to $topic");

    } catch (e, stacktrace) {
      debugPrint('MQTT subscribe error: $e\n$stacktrace');
    }
  }

  void topicToUnSubscribe(String topic) {
    if (_client == null) return;
    _subscription?.cancel();
    _subscription = null;
    if (currentTopic != null && currentTopic == topic) {
      _client!.unsubscribe(currentTopic!);
      currentTopic = null;
    } else {
      _client!.unsubscribe(topic);
    }
  }

  void onMqttPayloadReceived(String payload) {
    try {

      final jsonResponse = jsonDecode(payload);

      final payloadMessage = jsonDecode(payload);

     // providerState?.updateReceivedPayload(payloadMessage, true);

    } catch (e, stackTrace) {
      debugPrint('MQTT Payload Parsing Error: $e\n$stackTrace');
    }
  }


  Future<void> topicToPublishAndItsMessage(String message, String topic) async {

    if (!isConnected) {
      debugPrint("MQTT not connected. Cannot publish. Message dropped.");
      return;
    }
    Map<String, dynamic> bodyData = {'payload': message};
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(bodyData));

    try {
      _client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    } catch (e) {
      debugPrint("MQTT Publish Error: $e");
    }
  }

  void onSubscribed(String topic) {
    debugPrint('Subscribed to topic: $topic');
  }

  void onDisconnected() {
    debugPrint('MQTT disconnected');
    _connectionController.add(MqttConnectionState.disconnected);
  }

  void onConnected() {
    debugPrint('MQTT connected');
    _connectionController.add(MqttConnectionState.connected);
  }
}