import 'package:air_water/features/tank/presentation/widgets/pressure_gauge.dart';
import 'package:air_water/features/tank/presentation/widgets/solar_voltageI_idicator.dart';
import 'package:flutter/material.dart';

import 'battery_voltage_indicator.dart';
import 'generic_channel_indicator.dart';
import 'level_gauge.dart';

class DataChannelCard extends StatelessWidget {
  final String channelName;
  final dynamic value;
  final String unit;
  final String readingTime;
  final String thresholdText;

  const DataChannelCard({
    super.key,
    required this.channelName,
    required this.value,
    required this.unit,
    required this.readingTime,
    required this.thresholdText,
  });

  double get numericValue {
    if (value is num) {
      return (value as num).toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0.0;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 255,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =====================================================
            // HEADER
            // =====================================================

            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getChannelIcon(channelName),
                    color: primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    channelName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // =====================================================
            // VISUAL
            // =====================================================

            Expanded(
              child: _buildVisual(),
            ),

            const SizedBox(height: 6),

            // =====================================================
            // READING TIME
            // =====================================================

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 13,
                  color: Colors.grey,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    readingTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // =====================================================
            // THRESHOLD
            // =====================================================

            if (thresholdText.isNotEmpty)
              Text(
                thresholdText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisual() {
    switch (channelName.toLowerCase()) {
      case 'level':
        return LevelGauge(
          value: numericValue,
        );

      case 'pressure':
        return PressureGauge(
          value: numericValue,
        );

      case 'battery voltage':
        return BatteryVoltageIndicator(
          value: numericValue,
        );

      case 'solar voltage':
        return SolarVoltageIndicator(
          value: numericValue,
        );

      default:
        return GenericChannelIndicator(
          value: numericValue,
          unit: unit,
        );
    }
  }

  IconData _getChannelIcon(String name) {
    switch (name.toLowerCase()) {
      case 'level':
        return Icons.gas_meter_outlined;

      case 'pressure':
        return Icons.speed;

      case 'battery voltage':
        return Icons.battery_0_bar_rounded;

      case 'solar voltage':
        return Icons.solar_power;

      default:
        return Icons.sensors;
    }
  }
}