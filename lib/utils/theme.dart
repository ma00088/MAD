import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: Color(0xFF2A4F6E),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF2A4F6E)),
      titleTextStyle: TextStyle(
        color: Color(0xFF2A4F6E),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2A4F6E),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
  );
}

class AppColors {
  static const primary = Color(0xFF2A4F6E);
  static const secondary = Color(0xFFE67E22);
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
  static const success = Color(0xFF27AE60);
  static const error = Color(0xFFE74C3C);
}