import 'package:flutter/material.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import '../widgets/app_text.dart';

/// A reusable text field component with a label that matches the Ruby RX design system.
/// Provides full customization for colors, sizes, and styling while maintaining consistency.
class AppTextFieldWithLabelWidget extends StatelessWidget {
  // Required parameters
  final String label;
  final TextEditingController controller;
  final String hintText;

  // Optional input parameters
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  // Label styling parameters
  final double? labelFontSize;
  final FontWeight? labelFontWeight;
  final Color? labelColor;
  final int? labelMaxLines;
  final TextOverflow? labelOverflow;

  // Container styling parameters
  final double? containerHeight;
  final EdgeInsetsGeometry? containerPadding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;

  // TextField styling parameters
  final double? inputFontSize;
  final Color? inputTextColor;
  final Color? hintTextColor;
  final double? hintFontSize;
  final EdgeInsetsGeometry? contentPadding;

  // Layout parameters
  final double? spaceBetweenLabelAndField;

  const AppTextFieldWithLabelWidget({
    super.key,
    // Required
    required this.label,
    required this.controller,
    required this.hintText,
    // Optional input
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    // Label styling
    this.labelFontSize,
    this.labelFontWeight,
    this.labelColor,
    this.labelMaxLines,
    this.labelOverflow,
    // Container styling
    this.containerHeight,
    this.containerPadding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    // TextField styling
    this.inputFontSize,
    this.inputTextColor,
    this.hintTextColor,
    this.hintFontSize,
    this.contentPadding,
    // Layout
    this.spaceBetweenLabelAndField,
  });

  @override
  Widget build(BuildContext context) {
    // Default values based on Ruby RX design system
    final defaultLabelColor = labelColor ?? RubyColors.getTextColor(context);
    final defaultBackgroundColor =
        backgroundColor ?? RubyColors.primary1.withOpacity(0.3);
    final defaultBorderColor =
        borderColor ?? RubyColors.primary1.withOpacity(0.5);
    final defaultInputTextColor =
        inputTextColor ?? RubyColors.getTextColor(context);
    final defaultHintTextColor = hintTextColor ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AppText.inputLabel(
          label,
          color: defaultLabelColor,
          maxLines: labelMaxLines ?? 1,
          overflow: labelOverflow ?? TextOverflow.ellipsis,
        ),
        SizedBox(height: spaceBetweenLabelAndField ?? 8),

        // Text Field Container
        Container(
          height: containerHeight ?? 50,
          padding:
              containerPadding ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: defaultBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
            border: Border.all(
              color: defaultBorderColor,
              width: borderWidth ?? 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: inputFontSize ?? 14,
              color: defaultInputTextColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: defaultHintTextColor,
                fontSize: hintFontSize ?? 14,
              ),
              contentPadding: contentPadding ?? EdgeInsets.zero,
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pre-configured variants for common use cases

class AppTextFieldWithLabel {
  /// Standard Ruby RX text field (matches current design)
  static Widget standard({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return AppTextFieldWithLabelWidget(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      onChanged: onChanged,
    );
  }

  /// Compact version with smaller height and fonts
  static Widget compact({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return AppTextFieldWithLabelWidget(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      // Compact styling
      containerHeight: 40,
      labelFontSize: 12,
      inputFontSize: 12,
      hintFontSize: 12,
      spaceBetweenLabelAndField: 6,
      containerPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  /// Large version for important inputs
  static Widget large({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return AppTextFieldWithLabelWidget(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      // Large styling
      containerHeight: 60,
      labelFontSize: 16,
      inputFontSize: 16,
      hintFontSize: 16,
      spaceBetweenLabelAndField: 12,
      containerPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  /// Multi-line text area
  static Widget textArea({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 3,
    double? height,
  }) {
    return AppTextFieldWithLabelWidget(
      label: label,
      controller: controller,
      hintText: hintText,
      maxLines: maxLines,
      containerHeight: height ?? 80,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  /// Custom color variant
  static Widget withCustomColors({
    required String label,
    required TextEditingController controller,
    required String hintText,
    Color? backgroundColor,
    Color? borderColor,
    Color? labelColor,
    Color? inputTextColor,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return AppTextFieldWithLabelWidget(
      label: label,
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      labelColor: labelColor,
      inputTextColor: inputTextColor,
    );
  }
}
