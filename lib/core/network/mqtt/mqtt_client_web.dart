import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient setupMqttClient(String host, String clientId) {
  final client = MqttBrowserClient(host, clientId);
  client.websocketProtocols = ['mqtt'];
  return client;
}
