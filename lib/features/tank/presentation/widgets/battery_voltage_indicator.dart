import 'package:flutter/material.dart';

import 'battery_visual.dart';

class BatteryVoltageIndicator extends StatelessWidget {
  final double value;

  const BatteryVoltageIndicator({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    //
    // Assuming a 12V battery.
    //
    const minVoltage = 8.0;
    const maxVoltage = 13.0;

    final percentage =
    ((value - minVoltage) /
        (maxVoltage - minVoltage))
        .clamp(0.0, 1.0);

    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: percentage,
            ),
            duration:
            const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (
                context,
                animatedPercentage,
                child,
                ) {
              return SizedBox(
                width: 180,
                height: 70,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    BatteryVisual(
                      percentage:
                      animatedPercentage,
                    ),

                    const SizedBox(width: 14),

                    Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const Text(
                          'VOLTS',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}