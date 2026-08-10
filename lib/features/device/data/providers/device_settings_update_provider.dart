
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import 'device_settings_update_notifier.dart';

final deviceSettingsUpdateNotifierProvider =
StateNotifierProvider<
    DeviceSettingsUpdateNotifier,
    DeviceSettingsUpdateState>(
      (ref) {
    final mqttNotifier = ref.read(mqttProvider.notifier);

    final mqttService = ref.read(mqttServiceProvider);

    return DeviceSettingsUpdateNotifier(
      mqttNotifier,
      mqttService,
    );
  },
);