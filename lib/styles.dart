import 'package:flutter/material.dart';

// ==================== QRH Color Scheme for Night Mode ====================
class QRHColors {
  // Primary colors - High contrast for dark environment
  static const Color primaryBg = Color(0xFF0A0E27); // Deep space blue
  static const Color secondaryBg = Color(0xFF1A1F3A); // Navy blue
  static const Color accentBg = Color(0xFF252D4A); // Lighter navy

  // Text colors - High brightness for readability
  static const Color textPrimary = Color(0xFFE8F0FE); // Almost white
  static const Color textSecondary = Color(0xFF9DB4D4); // Light blue-gray
  static const Color textTertiary = Color(0xFF6B7D9A); // Dimmer blue-gray

  // Status colors - Optimized for aviation
  static const Color success = Color(0xFF00D084); // Cyan-green
  static const Color warning = Color(0xFFFFA500); // Amber
  static const Color caution = Color(0xFFFF9500); // Orange
  static const Color danger = Color(0xFFFF4D4D); // Red
  static const Color info = Color(0xFF00A8FF); // Bright cyan

  // Accent elements
  static const Color borderColor = Colors.lightBlue; // Subtle border
  static const Color dividerColor = Color(0xFF1E2847); // Divider line
  static const Color highlightColor = Color(0xFF00D084); // Highlight accent
}

// ==================== Theme Configuration ====================
ThemeData buildQRHTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: QRHColors.primaryBg,
    primaryColor: QRHColors.info,
    appBarTheme: AppBarTheme(
      backgroundColor: QRHColors.secondaryBg,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.5),
    ),
    colorScheme: ColorScheme.dark(
      primary: QRHColors.info,
      secondary: QRHColors.highlightColor,
      surface: QRHColors.secondaryBg,
      surfaceContainer: QRHColors.accentBg,
      onSurface: QRHColors.textPrimary,
      outline: QRHColors.borderColor,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: QRHColors.textPrimary),
      displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: QRHColors.textPrimary),
      headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: QRHColors.textPrimary),
      bodyLarge: const TextStyle(fontSize: 16, color: QRHColors.textPrimary),
      bodyMedium: const TextStyle(fontSize: 14, color: QRHColors.textSecondary),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: QRHColors.info,
      unselectedLabelColor: QRHColors.textSecondary,
      indicator: BoxDecoration(
        border: Border(bottom: BorderSide(color: QRHColors.info, width: 2)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: QRHColors.accentBg,
      labelStyle: const TextStyle(color: QRHColors.textSecondary),
      hintStyle: const TextStyle(color: QRHColors.textTertiary),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: QRHColors.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: QRHColors.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: QRHColors.info, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
