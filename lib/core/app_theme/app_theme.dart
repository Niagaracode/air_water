import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color primaryDark = const Color(0xFF141E7A);
Color primary = const Color(0xFF141E7A);
Color primaryLight = const Color(0xFF98A0E6);
Color primaryBackground = const Color(0xFFF8F6F6);
Color primaryTextColor = const Color(0xFF333333);
Color secondaryTextColor = const Color(0xFF666666);
/*Color borderColor = const Color(0xFFE0E0E0);
Color primaryDeep = const Color(0xFF1B1B4B);
Color infoBackground = const Color(0xFFE8EFFF);
Color cardBackgroundColor = const Color(0xFFF8F9FD);
Color greyBackgroundColor = const Color(0xFFF5F6FA);
Color breadcrumbColor = const Color(0xFF5C6AC4);*/

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColorDark: primaryDark,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor: primaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    colorScheme: ColorScheme.light(
      primary: primary,
      surface: const Color(0xFFF8F9FD),   // container background
      surfaceContainer: const Color(0xFFF5F6FA), // light cards/inputs
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: primary,
      elevation: 1,
      labelType: NavigationRailLabelType.all,
      indicatorColor: primaryLight,
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return primaryLight.withOpacity(0.1);
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.black;
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.black,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>(
          (states) => BorderSide(color: primaryLight, width: 1),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: Colors.black),
      titleMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
      titleSmall: GoogleFonts.roboto(fontSize: 12, color: Colors.black),

      headlineLarge: GoogleFonts.roboto(
        fontSize: 15,
        color: const Color(0xFF1E1E1E),
        fontWeight: FontWeight.bold,
      ), // siva
      headlineSmall: GoogleFonts.roboto(
        fontSize: 13,
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ), // siva
      labelLarge: GoogleFonts.roboto(
        fontSize: 15,
        color: const Color(0xFF1E1E1E),
        fontWeight: FontWeight.bold,
      ), // siva
      labelSmall: GoogleFonts.roboto(
        fontSize: 13,
        color: const Color(0xFF3C3C3C),
      ), // siva

      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 13,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[100],
      shadowColor: Colors.black,
      surfaceTintColor: Colors.teal[200],
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    ),
    cardColor: Colors.white,
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColorDark: primary,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor: primaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 22),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: Colors.white70,
      labelColor: Colors.white70,
      unselectedLabelColor: Colors.white54,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        side: const BorderSide(color: Colors.white),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: primary,
      elevation: 0,
      labelType: NavigationRailLabelType.all,
      indicatorColor: primary,
      unselectedIconTheme: const IconThemeData(color: Colors.white54),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return lightTheme.primaryColor.withAlpha(1);
          }
          return Colors.grey[300];
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.black;
        }),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.black,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? Colors.blueGrey
                : Colors.grey,
            width: 0.5,
          ),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.roboto(fontSize: 22, color: Colors.black),
      titleMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
      titleSmall: GoogleFonts.roboto(fontSize: 12, color: Colors.black),

      headlineLarge: GoogleFonts.roboto(
        fontSize: 15,
        color: Colors.white70,
        fontWeight: FontWeight.bold,
      ), // siva
      headlineSmall: GoogleFonts.roboto(
        fontSize: 13,
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ), // siva
      labelLarge: GoogleFonts.roboto(
        fontSize: 15,
        color: Colors.white70,
        fontWeight: FontWeight.bold,
      ), // siva
      labelSmall: GoogleFonts.roboto(fontSize: 13, color: Colors.grey), // siva

      bodyLarge: GoogleFonts.roboto(fontSize: 15, color: Colors.black87),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 13,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white24,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.teal[200],
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    ),
  );
}
