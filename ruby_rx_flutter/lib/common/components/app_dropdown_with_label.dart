import 'package:flutter/material.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import '../widgets/app_text.dart';

/// A reusable dropdown field component with a label that matches the Ruby RX design system.
/// Provides full customization for colors, sizes, and styling while maintaining consistency.
class AppDropdownWithLabel extends StatelessWidget {
  // Required parameters
  final String label;
  final String? value;
  final List<String> items;
  final String hintText;
  final Function(String?) onChanged;

  // Optional parameters
  final bool isRequired;
  final String? Function(String?)? validator;

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

  // Dropdown styling parameters
  final double? dropdownFontSize;
  final Color? dropdownTextColor;
  final Color? hintTextColor;
  final double? hintFontSize;
  final Color? iconColor;

  // Layout parameters
  final double? spaceBetweenLabelAndField;

  const AppDropdownWithLabel({
    super.key,
    // Required
    required this.label,
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChanged,
    // Optional
    this.isRequired = false,
    this.validator,
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
    // Dropdown styling
    this.dropdownFontSize,
    this.dropdownTextColor,
    this.hintTextColor,
    this.hintFontSize,
    this.iconColor,
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
    final defaultDropdownTextColor =
        dropdownTextColor ?? RubyColors.getTextColor(context);
    final defaultHintTextColor = hintTextColor ?? Colors.grey;
    final defaultIconColor = iconColor ?? RubyColors.primary1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AppText.inputLabel(
          isRequired ? '$label *' : label,
          color: defaultLabelColor,
          maxLines: labelMaxLines ?? 1,
          overflow: labelOverflow ?? TextOverflow.ellipsis,
        ),
        SizedBox(height: spaceBetweenLabelAndField ?? 8),

        // Dropdown Container
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value?.isEmpty == true ? null : value,
              hint: AppText.bodyMedium(hintText, color: defaultHintTextColor),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: defaultIconColor),
              style: TextStyle(
                fontSize: dropdownFontSize ?? 14,
                color: defaultDropdownTextColor,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: AppText.bodyMedium(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: defaultDropdownTextColor,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pre-configured variants for common use cases
class AppDropdownWithLabel_ {
  /// Standard Ruby RX dropdown field (matches current design)
  static Widget standard({
    required String label,
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return AppDropdownWithLabel(
      label: label,
      value: value,
      items: items,
      hintText: hintText,
      onChanged: onChanged,
      isRequired: isRequired,
      validator: validator,
    );
  }

  /// Compact version with smaller height and fonts
  static Widget compact({
    required String label,
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return AppDropdownWithLabel(
      label: label,
      value: value,
      items: items,
      hintText: hintText,
      onChanged: onChanged,
      isRequired: isRequired,
      // Compact styling
      containerHeight: 40,
      labelFontSize: 12,
      dropdownFontSize: 12,
      hintFontSize: 12,
      spaceBetweenLabelAndField: 6,
      containerPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  /// Large version for important dropdowns
  static Widget large({
    required String label,
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return AppDropdownWithLabel(
      label: label,
      value: value,
      items: items,
      hintText: hintText,
      onChanged: onChanged,
      isRequired: isRequired,
      // Large styling
      containerHeight: 60,
      labelFontSize: 16,
      dropdownFontSize: 16,
      hintFontSize: 16,
      spaceBetweenLabelAndField: 12,
      containerPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  /// Custom color variant
  static Widget withCustomColors({
    required String label,
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
    Color? backgroundColor,
    Color? borderColor,
    Color? labelColor,
    Color? dropdownTextColor,
    bool isRequired = false,
  }) {
    return AppDropdownWithLabel(
      label: label,
      value: value,
      items: items,
      hintText: hintText,
      onChanged: onChanged,
      isRequired: isRequired,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      labelColor: labelColor,
      dropdownTextColor: dropdownTextColor,
    );
  }
}

/// Predefined dropdown options for common medical fields
class MedicalDropdownOptions {
  /// Frequency options for medication
  static const List<String> frequency = [
    'Once a day',
    'Twice a day',
    'Thrice a day',
    'Once weekly',
    'Twice weekly',
    'Once a month',
  ];

  /// Duration options for medication
  static const List<String> duration = [
    '1 Day',
    '2 Days',
    '3 Days',
    '1 Week',
    '2 Weeks',
    '3 Weeks',
    '1 Month',
    '2 Months',
    '3 Months',
  ];

  /// Gender options
  static const List<String> gender = ['Male', 'Female', 'Other'];

  /// Common medical conditions (can be expanded)
  static const List<String> commonConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Kidney Disease',
    'Liver Disease',
    'Thyroid Disorder',
    'Arthritis',
    'Depression',
    'Anxiety',
    'None',
    'Other',
  ];
}
