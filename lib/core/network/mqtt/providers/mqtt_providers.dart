import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../mqtt_service.dart';
import 'mqtt_notifier.dart';
import '../models/mqtt_message.dart';
import '../models/mqtt_connection_state.dart';

// Provider for the MQTT service instance
final mqttServiceProvider = Provider<MqttService>((ref) {
  return MqttService();
});

// Provider for the MQTT notifier (state management)
final mqttProvider = StateNotifierProvider<MqttNotifier, MqttConnectionStateModel>(
      (ref) => MqttNotifier(ref.watch(mqttServiceProvider)),
);

// Provider to get last message for a specific topic
final mqttLastMessageProvider = Provider.family<MqttMessage?, String>(
      (ref, topic) {
    final mqttNotifier = ref.watch(mqttProvider.notifier);
    return mqttNotifier.getLastMessage(topic);
  },
);

// Provider for subscribing to a topic and receiving real-time updates
final mqttTopicStreamProvider = StreamProvider.family<MqttMessage, String>(
      (ref, topic) {
    final controller = StreamController<MqttMessage>.broadcast();

    final mqttNotifier = ref.read(mqttProvider.notifier);

    ref.onDispose(() {
      controller.close();
      mqttNotifier.unsubscribeFromTopic(topic);
    });

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