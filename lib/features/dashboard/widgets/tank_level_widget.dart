import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TankLevelWidget extends StatelessWidget {
  final double level;
  final String svgAsset;

  const TankLevelWidget({
    super.key,
    required this.level,
    required this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    const tankWidth = 120.0;
    const tankHeight = 200.0;

    // Height of the cylindrical body
    const liquidAreaHeight = 128.0;

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
            left: - 17.5,
            right: 24,
            bottom: 47,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  width: 61,
                  height: liquidAreaHeight * (level / 100),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.lightBlueAccent,
                        Colors.blue.shade700,
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
                color: Colors.blue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                "${level.toStringAsFixed(0)} %",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //--------------------------------------------------
          // SCALE
          //--------------------------------------------------

          Positioned(
            left: 70,
            top: 24,
            bottom: 45,
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