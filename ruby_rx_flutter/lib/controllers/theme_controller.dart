import 'package:flutter/material.dart';

import 'package:get/get.dart';

class ThemeController extends GetxController {
  // Observable theme mode - default to light mode
  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;

  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode.value;

  // Check if current theme is dark
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return _themeMode.value == ThemeMode.dark;
  }


  // Toggle between light and dark theme
  void toggleTheme() {
    if (_themeMode.value == ThemeMode.light) {
      _themeMode.value = ThemeMode.dark;
    } else {
      _themeMode.value = ThemeMode.light;
    }

    // Apply the theme change
    Get.changeThemeMode(_themeMode.value);

    // You can add logic here to save theme preference to storage
    // For example: _saveThemeToStorage();
  }

  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  // Switch to light theme
  void setLightTheme() {
    setThemeMode(ThemeMode.light);
  }

  // Switch to dark theme
  void setDarkTheme() {
    setThemeMode(ThemeMode.dark);
  }

  // Switch to system theme
  void setSystemTheme() {
    setThemeMode(ThemeMode.system);
  }
}
