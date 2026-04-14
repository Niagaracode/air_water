import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/mqtt/models/mqtt_connection_state.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../../core/user_config/user_role_provider.dart';
import 'package:air_water/features/alarm/presentation/controller/alarm_provider.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/technician_dashboard.dart';


class DashboardWide extends ConsumerStatefulWidget {
  const DashboardWide({super.key});

  @override
  ConsumerState<DashboardWide> createState() => _DashboardWideState();
}

class _DashboardWideState extends ConsumerState<DashboardWide> {

  final String tankStatusTopic = 'tweet';
  final String alarmTopic = 'alarm/trigger';

  StreamSubscription<MqttMessage>? _tankSubscription;
  StreamSubscription<MqttMessage>? _alarmSubscription;


  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alarmProvider.notifier).loadAlarms();
      ref.read(tankProvider.notifier).loadGroupedTanks();
    });
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // Subscribe to topics after a short delay to ensure connection
    Future.delayed(const Duration(seconds: 2), () {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.subscribeToTopic(tankStatusTopic);
      mqttNotifier.subscribeToTopic(alarmTopic);
    });
  }


  @override
  Widget build(BuildContext context) {

    final connectionState = ref.watch(mqttProvider);

    // Watch real-time streams for topics
    final tankStatusStream = ref.watch(mqttTopicStreamProvider(tankStatusTopic));
    final alarmStream = ref.watch(mqttTopicStreamProvider(alarmTopic));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Connection Status Widget
            _buildConnectionStatus(connectionState),
            const SizedBox(height: 16),

            // Dashboard Header
            const DashboardHeader(),
            const SizedBox(height: 32),

            // Listen to tank status updates
            _buildTankStatusListener(tankStatusStream),

            // Listen to alarm updates
            _buildAlarmListener(alarmStream),

            // Main content
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTankStatusListener(AsyncValue<MqttMessage> streamData) {
    return streamData.when(
      data: (message) {
        // This will be called every time a new message arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleTankStatusUpdate(message);
        });
        return const SizedBox.shrink();
      },
      error: (error, stack) {
        debugPrint('Tank status stream error: $error');
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildAlarmListener(AsyncValue<MqttMessage> streamData) {
    return streamData.when(
      data: (message) {
        // This will be called every time a new alarm arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAlarmTrigger(message);
        });
        return const SizedBox.shrink();
      },
      error: (error, stack) {
        debugPrint('Alarm stream error: $error');
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildConnectionStatus(MqttConnectionStateModel state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: state.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.isConnected ? 'MQTT Connected' : 'MQTT Disconnected',
            style: TextStyle(
              color: state.isConnected ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
          if (state.isConnecting) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  void _handleTankStatusUpdate(MqttMessage message) {
    final waterLevel = message.data['waterLevel'];
    final tankId = message.data['tankId'];

    debugPrint('📊 Tank $tankId Status: Water Level $waterLevel%');

    // Update your tank provider here
    /*ref.read(tankProvider.notifier).updateTankStatus(
      tankId,
      waterLevel,
      message.timestamp,
    );*/
  }

  void _handleAlarmTrigger(MqttMessage message) {
    final alarmType = message.data['type'];
    final messageText = message.data['message'];

    debugPrint('🚨 ALARM: $alarmType - $messageText');

    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messageText ?? 'Alarm triggered'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );

    // Add to alarms list
    /*ref.read(alarmProvider.notifier).addAlarm(
      type: alarmType,
      message: messageText,
      timestamp: message.timestamp,
    );*/
  }

  Widget _buildMainContent() {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == UserRole.technician) {
          return const TechnicianDashboard();
        }
        return const Center(
          child: Text(
            'Admin Dashboard Content Coming Soon',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  @override
  void dispose() {
    // Unsubscribe from topics
    final mqttNotifier = ref.read(mqttProvider.notifier);
    mqttNotifier.unsubscribeFromTopic(tankStatusTopic);
    mqttNotifier.unsubscribeFromTopic(alarmTopic);

    super.dispose();
  }

}