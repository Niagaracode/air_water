import 'package:flutter/material.dart';

class SolarVoltageIndicator extends StatefulWidget {
  final double value;

  const SolarVoltageIndicator({
    super.key,
    required this.value,
  });

  @override
  State<SolarVoltageIndicator> createState() =>
      _SolarVoltageIndicatorState();
}

class _SolarVoltageIndicatorState
    extends State<SolarVoltageIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (
            context,
            child,
            ) {
          final scale =
              0.90 +
                  (_controller.value * 0.12);

          return Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFFFB020,
                    ).withValues(
                      alpha: 0.12 +
                          (_controller.value *
                              0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    size: 36,
                    color: Color(
                      0xFFF59E0B,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                widget.value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Text(
                'VOLTS',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.bolt,
                    size: 12,
                    color: Color(
                      0xFFF59E0B,
                    ),
                  ),
                  Text(
                    ' SOLAR ACTIVE',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(
                        0xFFF59E0B,
                      ),
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}