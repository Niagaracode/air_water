import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../../config/app_config.dart';
import '../../constants/app_constants.dart';

MqttClient setupMqttClient(String host, String clientId) {
  String cleanHost = host;
  bool secure = false;
  if (host.startsWith('wss://')) {
    cleanHost = host.substring(6);
    secure = true;
  } else if (host.startsWith('ws://')) {
    cleanHost = host.substring(5);
  }
  
  // Remove port or path suffix if present
  final colonIndex = cleanHost.indexOf(':');
  if (colonIndex != -1) {
    cleanHost = cleanHost.substring(0, colonIndex);
  } else {
    final slashIndex = cleanHost.indexOf('/');
    if (slashIndex != -1) {
      cleanHost = cleanHost.substring(0, slashIndex);
    }
  }

  final client = MqttServerClient.withPort(cleanHost, clientId, AppConfig.current.mqttWebPort);
  client.useWebSocket = true;
  client.secure = secure;
  return client;
}
