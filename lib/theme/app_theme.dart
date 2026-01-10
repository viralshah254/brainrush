import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color darkCard = Color(0xFF161B33);
  
  // Neon Colors
  static const Color primaryNeon = Color(0xFF00F5FF);    // Cyan
  static const Color secondaryNeon = Color(0xFFFF006E);  // Pink
  static const Color accentNeon = Color(0xFF8338EC);     // Purple
  static const Color successNeon = Color(0xFF00FF00);    // Green
  static const Color warningNeon = Color(0xFFFFBE0B);    // Yellow
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryNeon, accentNeon],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: darkCard,
        background: darkBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
        bodySmall: TextStyle(
          color: Colors.white60,
          fontSize: 14,
        ),
      ),
    );
  }
}
