import 'dart:ui';
import 'app_config.dart';

const airWaterConfig = AppConfig(
  appName: 'AIR WATER',

  apiUrl: 'https://irrigationcare.niagaraautomation.com:4000/api',

  // Web MQTTcd
  mqttWebHost: 'irrigationcare.niagaraautomation.com',
  mqttWebPort: 9443,

  // Mobile MQTT
  mqttMobileHost: 'irrigationcare.niagaraautomation.com',
  mqttMobilePort: 8883,
  mqttSecure: true,

  mqttUserName: 'mqttuser',
  mqttPassword: 'Mqtt@456',

  encryptionKey: '0febba516bd1c549147a823b127c96e0',
  packageName: 'com.airwater.monitor',

  primaryColor: Color(0xFF141E7A),
  primaryLightColor: Color(0xFF98A0E6),
  primaryDarkColor: Color(0xFF141E7A),
  backgroundColor: Color(0xFFFFFFFF),

  appLogoPath: 'assets/logos/airwater/app_logo.svg',
  companyLogoPath: 'assets/logos/airwater/company_logo.svg',
  companySmallLogoPath: 'assets/logos/airwater/company_logo_small.svg',
  tankImgPath: 'assets/images/tank.svg',
);