
import '../../config/app_config.dart';

class Env {
  static String get apiUrl => AppConfig.current.apiUrl;
  static String get mqttWebUrl => AppConfig.current.mqttWebHost;
}