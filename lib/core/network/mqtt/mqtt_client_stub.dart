import 'package:mqtt_client/mqtt_client.dart';

MqttClient setupMqttClient({
  required String host,
  required int port,
  required String clientId,
  required bool secure,
}) {
  throw UnsupportedError(
    'MQTT is not supported on this platform.',
  );
}