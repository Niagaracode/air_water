import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient setupMqttClient({
  required String host,
  required int port,
  required String clientId,
  required bool secure,
}) {
  final protocol = secure ? 'wss' : 'ws';

  final client = MqttBrowserClient(
    '$protocol://$host:$port/mqtt',
    clientId,
  );

  client.websocketProtocols = const ['mqtt'];

  return client;
}
