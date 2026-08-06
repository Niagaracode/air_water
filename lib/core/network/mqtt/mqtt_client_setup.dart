import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_native.dart'
if (dart.library.html) 'mqtt_client_web.dart';

class MqttClientSetup {
  const MqttClientSetup._();

  static MqttClient create({
    required String host,
    required int port,
    required String clientId,
    required bool secure,
  }) {
    final client = setupMqttClient(
      host: host,
      port: port,
      clientId: clientId,
      secure: secure,
    );

    // Common configuration for all platforms
    client.keepAlivePeriod = 60;
    client.autoReconnect = false;
    client.logging(on: false);

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    return client;
  }
}