import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/url_strategy/url_strategy.dart';
import 'core/app_theme/app_theme.dart';
import 'core/network/mqtt/providers/mqtt_providers.dart';
import 'core/router/app_router.dart';

void main() {

  usePathUrlStrategy();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  late final router;
  bool _mqttInitialized = false;

  @override
  void initState() {
    super.initState();

    router = AppRouter.createRouter(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMqtt();
    });
  }

  Future<void> _initializeMqtt() async {
    if (_mqttInitialized) return;
    _mqttInitialized = true;
    try {
      final mqtt = ref.read(mqttProvider.notifier);
      await mqtt.initializeAndConnect();

    } catch (e) {
      debugPrint(
        'MQTT Init Error: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Air Water',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}