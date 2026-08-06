import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient setupMqttClient({
  required String host,
  required int port,
  required String clientId,
  required bool secure,
}) {
  final client = MqttServerClient(host, clientId);

  client.port = port;
  client.secure = secure;

  // Enable this only if your broker expects MQTT over WebSocket
  client.useWebSocket = false;

  return client;
}