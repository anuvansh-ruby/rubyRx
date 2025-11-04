import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';

class MobileNumberInput extends StatelessWidget {
  final String? topLabel;
  final String? placeholder;
  final TextEditingController controller;
  final String countryCode;
  final bool isEnabled;

  // Color parameters
  final Color? labelColor;
  final Color? hintColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? backgroundColor;
  final Color? disabledBorderColor;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final Color? countryCodeTextColor;
  final Color? countryCodeBackgroundColor;

  // Size parameters
  final double? labelFontSize;
  final double? inputFontSize;
  final double? hintFontSize;
  final double? countryCodeFontSize;
  final double? borderRadius;
  final double? borderWidth;
  final double? focusedBorderWidth;
  final EdgeInsetsGeometry? contentPadding;
  final double? spaceBetweenLabelAndInput;
  final double? countryCodeWidth;

  const MobileNumberInput({
    super.key,
    this.topLabel,
    this.placeholder,
    required this.controller,
    required this.countryCode,
    this.isEnabled = true,
    // Color defaults
    this.labelColor,
    this.hintColor,
    this.borderColor,
    this.focusedBorderColor,
    this.backgroundColor,
    this.disabledBorderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.countryCodeTextColor,
    this.countryCodeBackgroundColor,
    // Size defaults
    this.labelFontSize,
    this.inputFontSize,
    this.hintFontSize,
    this.countryCodeFontSize,
    this.borderRadius,
    this.borderWidth,
    this.focusedBorderWidth,
    this.contentPadding,
    this.spaceBetweenLabelAndInput,
    this.countryCodeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = isEnabled
        ? (borderColor ?? RubyColors.lightGrey)
        : (disabledBorderColor ?? RubyColors.lightGrey);

    final effectiveBackgroundColor = isEnabled
        ? backgroundColor
        : (disabledBackgroundColor ?? RubyColors.lightGrey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topLabel != null) ...[
          AppText.bodyLarge(topLabel!, color: labelColor ?? RubyColors.black),
          SizedBox(height: spaceBetweenLabelAndInput ?? 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
            border: Border.all(
              color: effectiveBorderColor,
              width: borderWidth ?? 1,
            ),
            color: effectiveBackgroundColor,
          ),
          child: Row(
            children: [
              // Country code section
              Container(
                width: countryCodeWidth ?? 80,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular((borderRadius ?? 8) - 1),
                    bottomLeft: Radius.circular((borderRadius ?? 8) - 1),
                  ),
                ),
                child: AppText.bodyMedium(
                  countryCode,
                  color: countryCodeTextColor ?? RubyColors.grey,
                  textAlign: TextAlign.center,
                ),
              ),

              // Divider
              Container(height: 40, width: 1, color: effectiveBorderColor),

              // Phone number input
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isEnabled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      15,
                    ), // Max phone number length
                  ],
                  style: TextStyle(
                    fontSize: inputFontSize ?? 14,
                    color: isEnabled
                        ? RubyColors.black
                        : (disabledTextColor ?? RubyColors.grey),
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder ?? 'Enter phone number',
                    hintStyle: TextStyle(
                      color: hintColor ?? RubyColors.grey,
                      fontSize: hintFontSize ?? 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding:
                        contentPadding ??
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Example usage:
class ExampleUsage extends StatefulWidget {
  const ExampleUsage({super.key});

  @override
  _ExampleUsageState createState() => _ExampleUsageState();
}

class _ExampleUsageState extends State<ExampleUsage> {
  final TextEditingController _mobileController1 = TextEditingController();
  final TextEditingController _mobileController2 = TextEditingController();
  final TextEditingController _mobileController3 = TextEditingController();

  @override
  void dispose() {
    _mobileController1.dispose();
    _mobileController2.dispose();
    _mobileController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.heading5('Mobile Number Input Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Enabled mobile input with default styling
            MobileNumberInput(
              topLabel: 'Mobile Number',
              placeholder: 'Enter your number',
              countryCode: '+91',
              controller: _mobileController1,
              isEnabled: true,
            ),
            const SizedBox(height: 20),

            // Disabled mobile input
            MobileNumberInput(
              topLabel: 'Disabled Mobile Number',
              placeholder: 'This field is disabled',
              countryCode: '+1',
              controller: _mobileController2,
              isEnabled: false,
            ),
            const SizedBox(height: 20),

            // Custom styled mobile input
            MobileNumberInput(
              topLabel: 'Custom Styled Mobile',
              placeholder: 'Type number...',
              countryCode: '+44',
              controller: _mobileController3,
              isEnabled: true,
              // Custom colors
              labelColor: RubyColors.primary1,
              borderColor: RubyColors.primary1,
              focusedBorderColor: RubyColors.primary1,
              countryCodeBackgroundColor: RubyColors.primary1,
              countryCodeTextColor: RubyColors.primary1,
              backgroundColor: RubyColors.primary1,
              // Custom sizes
              labelFontSize: 18,
              inputFontSize: 16,
              countryCodeFontSize: 15,
              borderRadius: 12,
              borderWidth: 1.5,
              countryCodeWidth: 90,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            const SizedBox(height: 30),

            // Button to demonstrate getting values
            ElevatedButton(
              onPressed: () {
                print('Mobile 1: +91${_mobileController1.text}');
                print('Mobile 2: +1${_mobileController2.text}');
                print('Mobile 3: +44${_mobileController3.text}');
              },
              child: AppText.bodyMedium('Get Values'),
            ),
          ],
        ),
      ),
    );
  }
}
