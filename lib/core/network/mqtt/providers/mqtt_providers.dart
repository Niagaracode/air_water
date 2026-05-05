import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../mqtt_service.dart';
import 'mqtt_notifier.dart';
import '../models/mqtt_message.dart';
import '../models/mqtt_connection_state.dart';

// Singleton provider for MQTT service - persists across app lifecycle
final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService.instance;
  service.initialize();
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});

// StateNotifier provider - also persists
final mqttProvider = StateNotifierProvider<MqttNotifier, MqttConnectionStateModel>((ref) {
    final service = ref.watch(mqttServiceProvider);
    return MqttNotifier(service);
  },
);

// Provider to get last message for a specific topic
final mqttLastMessageProvider = Provider.family<MqttMessageModel?, String>((ref, topic) {
    final mqttNotifier = ref.watch(mqttProvider.notifier);
    return mqttNotifier.getLastMessage(topic);
  },
);

// Provider for subscribing to a topic and receiving real-time updates
final mqttTopicStreamProvider = StreamProvider.family<MqttMessageModel, String>((ref, topic) {
    final controller = StreamController<MqttMessageModel>.broadcast();
    final mqttNotifier = ref.read(mqttProvider.notifier);
    ref.onDispose(() {
      controller.close();
      mqttNotifier.unsubscribeFromTopic(topic);
    });

    // Microtask to avoid blocking UI
    Future.microtask(() async {
      await mqttNotifier.subscribeToTopic(topic, onMessage: (message) {
        if (!controller.isClosed) {
          controller.add(message);
        }
      });
    });

    return controller.stream;
  },
);