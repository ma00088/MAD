import 'package:flutter/material.dart';

class AppTheme {
  // New color scheme
  static const Color primaryRed = Color(0xFFD12149);   // Main red color
  static const Color textGray = Color(0xFF454744);     // Text color
  static const Color accentYellow = Color(0xFFFFC107); // Loading bar yellow
  
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryRed,
    scaffoldBackgroundColor: Colors.grey[50],
    colorScheme: ColorScheme.light(
      primary: primaryRed,
      secondary: accentYellow,
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryRed),
      titleTextStyle: TextStyle(
        color: textGray,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: primaryRed,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: textGray),
      bodyMedium: TextStyle(color: textGray),
      titleLarge: TextStyle(color: textGray, fontWeight: FontWeight.bold),
    ),
  );
}

class AppColors {
  static const Color primary = Color(0xFFD12149);      // Main red
  static const Color textPrimary = Color(0xFF454744);   // Dark gray text
  static const Color textSecondary = Color(0xFF666666); // Lighter gray
  static const Color accentYellow = Color(0xFFFFC107);  // Yellow for loading
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
}