import 'package:flutter/material.dart';

class AppColors {
  // Main theme colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFFF9800);
  static const Color tertiary = Color(0xFF26A69A);

  // Gradients and accent colors
  static const Color sunsetOrange = Color(0xFFFFA726);
  static const Color oceanBlue = Color(0xFF039BE5);
  static const Color tropicalGreen = Color(0xFF2E7D32);
  static const Color sandBeige = Color(0xFFFFECB3);
  static const Color skyBlue = Color(0xFFBBDEFB);
  static const Color coralPink = Color(0xFFFF8A65);

  // Neutral colors
  static const Color neutralDark = Color(0xFF212121);
  static const Color neutralMedium = Color(0xFF757575);
  static const Color neutralLight = Color(0xFFE0E0E0);
  static const Color neutralBackground = Color(0xFFF5F5F5);

  // Status colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Stat colors - specifically for profile stats
  static const Color rentedColor = Color(0xFF5C6BC0); // Indigo
  static const Color reviewColor = Color(0xFFFFB300); // Amber
  static const Color listedColor = Color(0xFF26A69A); // Teal
  static const Color activeRentalsColor = Color(0xFFEF5350); // Red

  // Gradient presets
  static const LinearGradient profileHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );
}
