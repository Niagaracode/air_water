import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../controller/tank_event_provider.dart';

class TankEventsTab extends ConsumerWidget {
  final int tankId;
  final String? day;

  const TankEventsTab({
    super.key,
    required this.tankId,
    required this.day,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final state = ref.watch(
      tankEventsProvider(
        TankEventParams(
          tankId: tankId,
          day: day!,
        ),
      ),
    );

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!),
      );
    }

    if (state.events.isEmpty) {
      return const Center(
        child: Text('No events found'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: state.events.length,
        itemBuilder: (context, index) {

          final event = state.events[index];

          return ListTile(
            leading: Icon(
              event.type == 'BATTERY'? Icons.battery_1_bar : Icons.warning_amber_rounded,
              color: event.status == 'Critical'
                  ? Colors.red
                  : Colors.orange,
            ),

            title: Text(event.type),

            subtitle: Text(
              '${event.message} • ${event.status}',
            ),

            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  event.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  DateFormat('dd MMM yyyy hh:mm a').format(
                    DateTime.parse(event.createdAt).toLocal(),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}