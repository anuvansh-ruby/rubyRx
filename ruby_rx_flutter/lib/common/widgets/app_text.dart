import 'package:flutter/material.dart';
import '../../utils/font_styles.dart';

/// Custom Text widget that automatically applies Poppins font through FontStyles
/// This widget replaces the standard Text widget throughout the app for consistency
class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle? style;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final TextDirection? textDirection;
  final String? semanticsLabel;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  });

  /// Convenience constructors for common text styles
  const AppText.heading1(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.heading1;

  const AppText.heading2(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.heading2;

  const AppText.heading3(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.heading3;

  const AppText.heading4(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.heading4;

  const AppText.heading5(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.heading5;

  const AppText.heading6(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.heading6;

  const AppText.bodyLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.bodyLarge;

  const AppText.bodyMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.bodyMedium;

  const AppText.bodySmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.bodySmall;

  const AppText.bodyUltraSmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.bodyUltraSmall;

  const AppText.subtitle1(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.subtitle1;

  const AppText.subtitle2(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.subtitle2;

  const AppText.buttonLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.buttonLarge;

  const AppText.buttonMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.buttonMedium;

  const AppText.buttonSmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.buttonSmall;

  const AppText.caption(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.caption;

  const AppText.captionBold(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.captionBold;

  const AppText.inputLabel(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.inputLabel;

  const AppText.linkText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.linkText;

  const AppText.errorText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.errorText;

  const AppText.successText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : style = AppTextStyle.successText;

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle;

    // Get the base style from AppTextStyle enum
    switch (style) {
      case AppTextStyle.heading1:
        baseStyle = FontStyles.heading1;
        break;
      case AppTextStyle.heading2:
        baseStyle = FontStyles.heading2;
        break;
      case AppTextStyle.heading3:
        baseStyle = FontStyles.heading3;
        break;
      case AppTextStyle.heading4:
        baseStyle = FontStyles.heading4;
        break;
      case AppTextStyle.heading5:
        baseStyle = FontStyles.heading5;
        break;
      case AppTextStyle.heading6:
        baseStyle = FontStyles.heading6;
        break;
      case AppTextStyle.bodyLarge:
        baseStyle = FontStyles.bodyLarge;
        break;
      case AppTextStyle.bodyMedium:
        baseStyle = FontStyles.bodyMedium;
        break;
      case AppTextStyle.bodySmall:
        baseStyle = FontStyles.bodySmall;
        break;
      case AppTextStyle.subtitle1:
        baseStyle = FontStyles.subtitle1;
        break;
      case AppTextStyle.subtitle2:
        baseStyle = FontStyles.subtitle2;
        break;
      case AppTextStyle.buttonLarge:
        baseStyle = FontStyles.buttonLarge;
        break;
      case AppTextStyle.buttonMedium:
        baseStyle = FontStyles.buttonMedium;
        break;
      case AppTextStyle.buttonSmall:
        baseStyle = FontStyles.buttonSmall;
        break;
      case AppTextStyle.caption:
        baseStyle = FontStyles.caption;
        break;
      case AppTextStyle.captionBold:
        baseStyle = FontStyles.captionBold;
        break;
      case AppTextStyle.inputLabel:
        baseStyle = FontStyles.inputLabel;
        break;
      case AppTextStyle.linkText:
        baseStyle = FontStyles.linkText;
        break;
      case AppTextStyle.errorText:
        baseStyle = FontStyles.errorText;
        break;
      case AppTextStyle.successText:
        baseStyle = FontStyles.successText;
        break;
      case AppTextStyle.bodyUltraSmall:
        baseStyle = FontStyles.bodyUltraSmall;
        break;
      case null:
        baseStyle = FontStyles.bodyMedium; // Default style
        break;
    }

    // Apply color override if provided
    final finalStyle = color != null
        ? baseStyle.copyWith(color: color)
        : baseStyle;

    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      textDirection: textDirection,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Enum to define available text styles for AppText widget
enum AppTextStyle {
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  bodyLarge,
  bodyMedium,
  bodySmall,
  subtitle1,
  subtitle2,
  buttonLarge,
  buttonMedium,
  buttonSmall,
  caption,
  captionBold,
  inputLabel,
  linkText,
  errorText,
  successText,
  bodyUltraSmall,
}
