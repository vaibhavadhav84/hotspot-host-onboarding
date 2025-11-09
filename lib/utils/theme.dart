// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color base1 = Color(0xFF101010);
  static const Color surfaceWhite = Color(0xFF1F1F1F);
  static const Color text1 = Colors.white;
  static const Color text2 = Color(0xFFAAAAAA);
  static const Color primaryAccent = Color(0xFF6169FF);
  static const Color positive = Color(0xFF58FF89);
  static const Color negative = Color(0xFFFF5252);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: base1,
    primaryColor: primaryAccent,
    colorScheme: const ColorScheme.dark(
      primary: primaryAccent,
      surface: surfaceWhite,
      onPrimary: Colors.white,
      onSurface: Colors.white70,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: text1,
      ),
      displayMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: text1,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: text1),
      bodyMedium: TextStyle(fontSize: 14, color: text2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: text2),
    ),
  );
}
