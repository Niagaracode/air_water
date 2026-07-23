import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../core/network/mqtt/providers/mqtt_notifier.dart';
import '../../../core/network/mqtt/providers/mqtt_providers.dart';
import 'dashboard_provider.dart';

final dashboardControllerProvider =
AsyncNotifierProvider<DashboardController, void>(
  DashboardController.new,
);

class DashboardController extends AsyncNotifier<void> {

  late final MqttNotifier mqttNotifier;
  final String topic = kIsWeb ? 'tweet' : 'tweet';
  bool _initialized = false;

  @override
  Future<void> build() async {
    if (_initialized) return;

    _initialized = true;
    mqttNotifier = ref.read(mqttProvider.notifier);
    await _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    await mqttNotifier.initializeAndConnect();
    await mqttNotifier.subscribeToTopic(
      topic,
      onMessage: _onMqttMessage,
    );
  }

  void _onMqttMessage(MqttMessageModel msg) {
   // print("✅ MQTT MESSAGE: ${msg.rawPayload}");
    final parsed = _parseMqtt(msg.data);
    ref.read(tankDataProvider.notifier)
        .updateFromMqtt(parsed);
  }

  Map<String, dynamic> _parseMqtt(Map<String, dynamic> json) {

    final result = <String, dynamic>{};
    result['deviceId'] = json['cC'];
    final cM = json['cM'] ?? '';
    final matches = RegExp(r'([A-Z]+):([\d.]+)').allMatches(cM);

    for (var m in matches) {
      final key = m.group(1);
      final value = double.tryParse(m.group(2)!);

      switch (key) {
        case 'TNP':
          result['level'] = value;
          break;

        case 'PTN':
          result['pressure'] = value;
          break;

        case 'BAT':
          result['batteryV'] = value;
          break;

        case 'SOL':
          result['solarV'] = value;
          break;
      }
    }

    final date = json['cD']?.toString().trim() ?? '';
    final time = json['cT']?.toString().trim() ?? '';
    if (date.isNotEmpty && time.isNotEmpty) {
      try {
        result['lastUpdate'] =
            DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse('$date $time');

      } catch (_) {
        result['lastUpdate'] = DateTime.now();
      }
    }
    return result;
  }
}