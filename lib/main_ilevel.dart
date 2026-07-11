import 'config/app_config.dart';
import 'config/ilevel_config.dart';
import 'main.dart' as runner;

Future<void> main() async {
  AppConfig.current = iLevelConfig;
  runner.main();
}