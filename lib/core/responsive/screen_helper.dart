import 'screen_type.dart';

class ScreenHelper {
  static const double narrowMaxWidth = 600;
  static const double middleMaxWidth = 1024;

  static ScreenType getScreenType(double width) {
    if (width <= narrowMaxWidth) {
      return ScreenType.narrow;
    } else if (width <= middleMaxWidth) {
      return ScreenType.middle;
    } else {
      return ScreenType.wide;
    }
  }
}