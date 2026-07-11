import 'config/app_config.dart';
import 'config/airwater_config.dart';
import 'main.dart' as runner;

Future<void> main() async {
  AppConfig.current = airWaterConfig;
  runner.main();
}