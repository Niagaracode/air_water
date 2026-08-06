// lib/core/network/mqtt/providers/mqtt_providers.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../mqtt_service.dart';
import 'mqtt_notifier.dart';
import '../models/mqtt_message.dart';
import '../models/mqtt_connection_state.dart';

// ==================== SERVICE PROVIDER ====================

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService.instance;

  // Initialize only once
  service.initialize();

  ref.onDispose(() {
    // Don't dispose the service as it should stay alive
    // But we can clean up if needed
  });

  return service;
});

// ==================== NOTIFIER PROVIDER ====================

final mqttProvider = StateNotifierProvider<MqttNotifier, MqttConnectionStateModel>(
      (ref) {
    final service = ref.watch(mqttServiceProvider);
    return MqttNotifier(service);
  },
);

// ==================== LAST MESSAGE PROVIDER ====================

final mqttLastMessageProvider = Provider.family<MqttMessageModel?, String>(
      (ref, topic) {
    final mqttNotifier = ref.watch(mqttProvider.notifier);
    return mqttNotifier.getLastMessage(topic);
  },
);

// ==================== ALL MESSAGES PROVIDER ====================

final mqttAllMessagesProvider = Provider<Map<String, MqttMessageModel>>(
      (ref) {
    final mqttNotifier = ref.watch(mqttProvider.notifier);
    return mqttNotifier.getAllMessages();
  },
);

// ==================== TOPIC STREAM PROVIDER ====================

final mqttTopicStreamProvider = StreamProvider.family<MqttMessageModel, String>(
      (ref, topic) {
    final controller = StreamController<MqttMessageModel>.broadcast();
    final mqttNotifier = ref.read(mqttProvider.notifier);

    late final Function(MqttMessageModel) callback;

    callback = (message) {
      if (!controller.isClosed) {
        debugPrint('📤 Stream adding message for $topic');
        controller.add(message);
      }
    };

    // Subscribe
    Future.microtask(() async {
      try {
        debugPrint('📡 Initializing stream for topic: $topic');
        await mqttNotifier.initializeAndConnect();
        await mqttNotifier.subscribeToTopic(topic, onMessage: callback);
        debugPrint('✅ Stream ready for topic: $topic');
      } catch (e) {
        debugPrint('❌ Stream initialization error: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });

    ref.onDispose(() {
      debugPrint('🧹 Cleaning up stream for topic: $topic');
      controller.close();
      mqttNotifier.unsubscribeFromTopic(topic, onMessage: callback);
    });

    return controller.stream;
  },
);

// ==================== DEBUG PROVIDER ====================

final mqttDebugProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(mqttProvider.notifier);

  return {
    'isConnected': ref.watch(mqttProvider.select((state) => state.isConnected)),
    'isConnecting': ref.watch(mqttProvider.select((state) => state.isConnecting)),
    'error': ref.watch(mqttProvider.select((state) => state.error)),
    'lastConnectedAt': ref.watch(mqttProvider.select((state) => state.lastConnectedAt)),
    'subscribedTopics': notifier.getSubscribedTopics(),
    'totalMessages': ref.watch(mqttAllMessagesProvider).length,
  };
});