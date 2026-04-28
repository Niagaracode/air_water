import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/mqtt/providers/mqtt_providers.dart';

class MqttConnectionStatus extends ConsumerWidget {
  const MqttConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(mqttProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: connectionState.isConnected
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connectionState.isConnected
              ? Colors.green.shade200
              : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connectionState.isConnected
                ? Icons.circle
                : Icons.pause_circle_outline,
            size: 14,
            color: connectionState.isConnected
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            connectionState.isConnected
                ? 'System Online'
                : 'System Offline',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: connectionState.isConnected
                  ? Colors.green.shade800
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}