import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class ThemeController extends GetxController {
  final RxBool _isDarkMode = false.obs;
  final RxBool _isSystemTheme = true.obs;

  // Getters
  bool get isDarkMode => _isDarkMode.value;
  bool get isSystemTheme => _isSystemTheme.value;
  ThemeMode get themeMode {
    if (_isSystemTheme.value) {
      return ThemeMode.system;
    }
    return _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  void onInit() {
    super.onInit();
    _loadThemeSettings();
  }

  // Load theme settings from SharedPreferences
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
      _isSystemTheme.value = prefs.getBool('isSystemTheme') ?? true;
    } catch (e) {
      print('Error loading theme settings: $e');
    }
  }

  // Save theme settings to SharedPreferences
  Future<void> _saveThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode.value);
      await prefs.setBool('isSystemTheme', _isSystemTheme.value);
    } catch (e) {
      print('Error saving theme settings: $e');
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode.value = !_isDarkMode.value;
    _isSystemTheme.value = false;
    await _saveThemeSettings();
    Get.changeThemeMode(themeMode);
  }

  // Set system theme
  Future<void> setSystemTheme() async {
    _isSystemTheme.value = true;
    await _saveThemeSettings();
    Get.changeThemeMode(themeMode);
  }

  // Set light theme
  Future<void> setLightTheme() async {
    _isDarkMode.value = false;
    _isSystemTheme.value = false;
    await _saveThemeSettings();
    Get.changeThemeMode(themeMode);
  }

  // Set dark theme
  Future<void> setDarkTheme() async {
    _isDarkMode.value = true;
    _isSystemTheme.value = false;
    await _saveThemeSettings();
    Get.changeThemeMode(themeMode);
  }

  // Get theme data
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.neutralBackground,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: Colors.white,
        background: AppColors.neutralBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.neutralDark,
        onBackground: AppColors.neutralDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.neutralDark,
        ),
        bodyMedium: TextStyle(
          color: AppColors.neutralDark,
        ),
        bodySmall: TextStyle(
          color: AppColors.neutralMedium,
        ),
        labelLarge: TextStyle(
          color: AppColors.neutralDark,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: AppColors.neutralDark,
        ),
        labelSmall: TextStyle(
          color: AppColors.neutralMedium,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.neutralDark,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neutralLight,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutralLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutralLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.neutralMedium),
        hintStyle: const TextStyle(color: AppColors.neutralMedium),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          color: Color(0xFFB0B0B0),
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          color: Color(0xFFB0B0B0),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
      ),
    );
  }
}
