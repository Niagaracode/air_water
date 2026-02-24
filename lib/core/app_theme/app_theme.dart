import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color primaryDark = const Color(0xFF141E7A);
Color primary = const Color(0xFF141E7A);
Color primaryLight = const Color(0xFF98A0E6);
Color primaryBackground = const Color(0xFFF0F2F8);
Color primaryTextColor = const Color(0xFF1A1A2E);
Color secondaryTextColor = const Color(0xFF6B7280);
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
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    colorScheme: ColorScheme.light(
      primary: primary,
      surface: const Color(0xFFF8F9FD), // container background
      surfaceContainer: const Color(0xFFF5F6FA), // light cards/inputs
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
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
          return primaryLight.withValues(alpha: 0.1);
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
        textStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
    ),
    textTheme: TextTheme(
      titleLarge: GoogleFonts.outfit(
        fontSize: 24,
        color: const Color(0xFF1A1A2E),
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        color: const Color(0xFF1A1A2E),
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        color: const Color(0xFF1A1A2E),
        fontWeight: FontWeight.w600,
      ),

      headlineLarge: GoogleFonts.outfit(
        fontSize: 16,
        color: const Color(0xFF1E1E1E),
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 15,
        color: const Color(0xFF1E1E1E),
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),

      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: const Color(0xFF1A1A2E),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF374151),
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF6B7280),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE5E7EB),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColorDark: primary,
    primaryColor: primary,
    primaryColorLight: primaryLight,
    scaffoldBackgroundColor: primaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
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
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF4B5563),
      ),
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
      titleLarge: GoogleFonts.outfit(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),

      headlineLarge: GoogleFonts.outfit(
        fontSize: 16,
        color: Colors.white70,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.grey,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 15,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      ),

      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white60,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
    ),
    cardTheme: CardThemeData(
      color: Colors.white10,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
