import 'package:flutter/material.dart';

class RubyColors {
  static const Color appColor = Color(0xFF0098DA);
  static const Color red = Color(0xFFFF0000);
  static const Color blue = Color(0xFF5697D7);
  static const Color yellow = Color(0xFFFFFF00);
  static const Color green = Color(0xFF196B19);
  static const Color orange = Color(0xFFFFA500);
  static const Color purple = Color(0xFF800080);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFCCCACA);
  static const Color grey = Color(0xFF808080);
  static const Color cyan = Color(0xFF00FFFF);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color brown = Color(0xFFA52A2A);
  static const Color primary1 = Color(0xFF64C8BE);
  static const Color primary2 = Color(0xFF1979D2);
  static const Color primary2Disabled = Color(0xFF0D3963);
  static const Color transparent = Color(0x00FFFFFF);
  static const Color background = Color.fromARGB(255, 187, 246, 224);

  // Additional colors found in the codebase
  static const Color darkBackgroundTop = Color(0xFF1A1A1A);
  static const Color darkBackgroundBottom = Color(0xFF0D1117);
  static const Color darkContainerBackground = Color(0xFF2A2A2A);
  static const Color otpPrimaryColor = Color(0xFF6366F1);
  static const Color otpBackgroundColor = Color(0xFFF8F9FA);
  static const Color otpBorderColor = Color(0xFFE5E7EB);
  static const Color otpSuccessColor = Color(0xFF10B981);
  static const Color otpBlueColor = Color(0xFF3B82F6);
  static const Color lightGreyBackground = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF616161);

  // Helper method to get adaptive text color based on theme
  static Color getTextColor(BuildContext context, {bool primary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (primary) {
      return isDark ? Colors.white : Colors.black87;
    }
    return isDark ? Colors.white70 : Colors.black87;
  }

  // Helper method to get adaptive icon color
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  // Helper method to get adaptive background colors
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkContainerBackground
        : white;
  }

  // Helper method to get adaptive border color
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkGrey
        : lightGrey;
  }

  // Helper method to get adaptive grey colors
  static Color getGreyColor(BuildContext context, {bool light = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (light) {
      return isDark ? darkGrey : lightGreyBackground;
    }
    return isDark ? mediumGrey : grey;
  }
}
