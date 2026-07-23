import 'package:mqtt_client/mqtt_client.dart';

MqttClient setupMqttClient(String host, String clientId) {
  throw UnsupportedError(
    'Cannot create MQTT client on this platform',
  );
}