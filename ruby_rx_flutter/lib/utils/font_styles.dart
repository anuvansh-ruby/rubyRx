import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized font styles utility class for consistent typography throughout the app
/// All text styles use Poppins font family with proper weights and sizes
class FontStyles {
  // Private constructor to prevent instantiation
  FontStyles._();

  /// Font family name for consistency
  static const String fontFamily = 'Poppins';

  /// Heading Styles
  static TextStyle get heading1 => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle get heading2 => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get heading3 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get heading4 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get heading5 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get heading6 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Body Text Styles
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get bodyUltraSmall => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  /// Button Text Styles
  static TextStyle get buttonLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get buttonMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get buttonSmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Caption and Subtitle Styles
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static TextStyle get captionBold => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get subtitle1 => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get subtitle2 => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Input Field Styles
  static TextStyle get inputText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get inputLabel => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get inputHint => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Colors.grey[600],
  );

  /// Error and Success Text Styles
  static TextStyle get errorText => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Colors.red[600],
  );

  static TextStyle get successText => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: Colors.green[600],
  );

  /// Link Styles
  static TextStyle get linkText => GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    decoration: TextDecoration.underline,
  );

  /// Monospace Style (for OTP/PIN inputs)
  static TextStyle get monospace => const TextStyle(
    fontFamily: 'monospace',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
  );

  /// Custom weight helpers
  static TextStyle poppins({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => GoogleFonts.poppins(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  /// Weight constants for easy access
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

/// Extension on TextStyle for easy color customization while maintaining Poppins font
extension TextStyleExtensions on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle withHeight(double height) => copyWith(height: height);
}
