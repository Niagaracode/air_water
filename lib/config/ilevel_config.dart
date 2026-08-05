import 'dart:ui';
import 'app_config.dart';

const iLevelConfig = AppConfig(
  appName: 'iLevel',
  apiUrl: 'http://localhost:4000/api',

  // Web MQTT
  mqttWebHost: 'wss://irrigationcare.niagaraautomation.com:9443/mqtt',
  mqttWebPort: 9443,

  // Mobile MQTT
  mqttMobileHost: '3.0.229.165',
  mqttMobilePort: 1883,

  mqttUserName: 'niagara',
  mqttPassword: 'niagara@123',

  encryptionKey: '0febba516bd1c549147a823b127c96e0',
  packageName: 'com.airwater.monitor',

  primaryColor: Color(0xFF009688),
  primaryLightColor: Color(0xFF80CBC4),
  primaryDarkColor: Color(0xFF00695C),
  backgroundColor: Color(0xFFFFFFFF),

  appLogoPath: 'assets/logos/ilevel/app_logo.svg',
  companyLogoPath: 'assets/logos/ilevel/company_logo.svg',
  companySmallLogoPath: 'assets/logos/ilevel/company_logo_small.svg',
  tankImgPath: 'assets/images/tank.svg',
);
