import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../mqtt_service.dart';
import 'mqtt_notifier.dart';
import '../models/mqtt_message.dart';
import '../models/mqtt_connection_state.dart';

/// ------------------------------------------------------------
/// MQTT SERVICE PROVIDER
/// ------------------------------------------------------------

final mqttServiceProvider = Provider<MqttService>((ref) {

  final service = MqttService.instance;

  /// Initialize only once
  service.initialize();

  /// IMPORTANT:
  /// Do NOT disconnect on provider dispose.
  /// MQTT should stay alive across navigation.

  return service;
});


/// ------------------------------------------------------------
/// MQTT NOTIFIER PROVIDER
/// ------------------------------------------------------------

final mqttProvider = StateNotifierProvider<
    MqttNotifier,
    MqttConnectionStateModel>(
      (ref) {

    final service = ref.watch(mqttServiceProvider);

    return MqttNotifier(service);
  },
);


/// ------------------------------------------------------------
/// LAST MESSAGE PROVIDER
/// ------------------------------------------------------------

final mqttLastMessageProvider =
Provider.family<MqttMessageModel?, String>(
      (ref, topic) {

    final mqttNotifier =
    ref.watch(mqttProvider.notifier);

    return mqttNotifier.getLastMessage(topic);
  },
);


/// ------------------------------------------------------------
/// MQTT TOPIC STREAM PROVIDER
/// ------------------------------------------------------------

final mqttTopicStreamProvider =
StreamProvider.family<MqttMessageModel, String>(
      (ref, topic) {

    final controller =
    StreamController<MqttMessageModel>.broadcast();

    final mqttNotifier =
    ref.read(mqttProvider.notifier);

    /// Store callback reference
    late final Function(MqttMessageModel) callback;

    callback = (message) {

      if (!controller.isClosed) {

        controller.add(message);
      }
    };

    /// Subscribe
    Future.microtask(() async {

      /// Ensure MQTT connected
      await mqttNotifier.initializeAndConnect();

      /// Subscribe topic
      await mqttNotifier.subscribeToTopic(
        topic,
        onMessage: callback,
      );
    });

    /// Cleanup only local stream
    ref.onDispose(() {

      controller.close();

      /// Optional:
      /// Remove ONLY callback
      /// Keep broker subscription alive

      mqttNotifier.unsubscribeFromTopic(
        topic,
        onMessage: callback,
      );
    });

    return controller.stream;
  },
);