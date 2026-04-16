// main.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/app_theme/app_theme.dart';
import 'core/network/mqtt/providers/mqtt_providers.dart';
import 'core/router/app_router.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _initializeMqtt();
      }
    });
  }

  Future<void> _initializeMqtt() async {
    if (_isInitialized) return;

    try {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      await mqttNotifier.initializeAndConnect();
      if (mounted) {
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Failed to initialize MQTT: $e');
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}