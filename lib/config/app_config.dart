import 'dart:ui';

class AppConfig {
  final String appName;
  final String apiUrl;

  // MQTT Web
  final String mqttWebHost;
  final int mqttWebPort;

  // MQTT Mobile
  final String mqttMobileHost;
  final int mqttMobilePort;
  final bool mqttSecure;

  final String mqttUserName;
  final String mqttPassword;

  final String encryptionKey;
  final String packageName;

  final Color primaryColor;
  final Color primaryLightColor;
  final Color primaryDarkColor;
  final Color backgroundColor;

  final String appLogoPath;
  final String companyLogoPath;
  final String companySmallLogoPath;
  final String tankImgPath;

  const AppConfig({
    required this.appName,
    required this.apiUrl,

    // MQTT Web
    required this.mqttWebHost,
    required this.mqttWebPort,

    // MQTT Mobile
    required this.mqttMobileHost,
    required this.mqttMobilePort,
    required this.mqttSecure,

    required this.mqttUserName,
    required this.mqttPassword,

    required this.encryptionKey,
    required this.packageName,

    required this.primaryColor,
    required this.primaryLightColor,
    required this.primaryDarkColor,
    required this.backgroundColor,

    required this.appLogoPath,
    required this.companyLogoPath,
    required this.companySmallLogoPath,
    required this.tankImgPath,
  });

  static late AppConfig current;
}