import 'package:flutter/material.dart';

class GenericChannelIndicator
    extends StatelessWidget {
  final double value;
  final String unit;

  const GenericChannelIndicator({
    super.key,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sensors,
            size: 42,
            color: Color(0xFF2563EB),
          ),

          const SizedBox(height: 8),

          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          Text(
            unit,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}