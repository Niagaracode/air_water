import 'dart:ui';

class AppConfig {
  final String appName;
  final String apiUrl;

  final String mqttWebHost;
  final int mqttWebPort;
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

  const AppConfig({
    required this.appName,
    required this.apiUrl,
    required this.mqttWebHost,
    required this.mqttWebPort,
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
  });

  static late AppConfig current;
}