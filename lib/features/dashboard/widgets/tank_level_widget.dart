import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/helpers/app_colors_helper.dart';

class TankLevelWidget extends StatelessWidget {
  final double level;
  final String svgAsset;
  final String gasType;

  const TankLevelWidget({
    super.key,
    required this.level,
    required this.svgAsset,
    required this.gasType,
  });

  @override
  Widget build(BuildContext context) {
    const tankWidth = 120.0;
    const tankHeight = 200.0;
    // Height of the cylindrical body
    const liquidAreaHeight = 169.0;

    return SizedBox(
      width: 160,
      height: tankHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          //--------------------------------------------------
          // WATER
          //--------------------------------------------------
          Positioned(
            left: - 17.9,
            right: 22,
            bottom: 30,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  width: 66,
                  height: liquidAreaHeight * (level / 100),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(7),
                      bottomRight: Radius.circular(7),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColorsHelper.getGasTypeColor(gasType).withValues(alpha: 0.3),
                        AppColorsHelper.getGasTypeColor(gasType).withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          //--------------------------------------------------
          // SVG
          //--------------------------------------------------
          SizedBox(
            width: tankWidth,
            height: tankHeight,
            child: SvgPicture.asset(
              svgAsset,
              fit: BoxFit.contain,
            ),
          ),

          //--------------------------------------------------
          // PERCENTAGE BADGE
          //--------------------------------------------------
          Positioned(
            left: 100,
            top: tankHeight - 32 - (liquidAreaHeight * level / 100) - 18,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColorsHelper.getGasTypeColor(gasType),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "${level.toStringAsFixed(0)} %",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          //--------------------------------------------------
          // SCALE
          //--------------------------------------------------
          Positioned(
            left: 72,
            top: 8,
            bottom: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("100", style: TextStyle(fontSize: 9)),
                Text("75", style: TextStyle(fontSize: 9)),
                Text("50", style: TextStyle(fontSize: 9)),
                Text("25", style: TextStyle(fontSize: 9)),
                Text("0", style: TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}