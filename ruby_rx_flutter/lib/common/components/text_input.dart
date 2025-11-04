import 'package:flutter/material.dart';
import 'package:ruby_rx_flutter/common/color_pallet/color_pallet.dart';
import 'package:ruby_rx_flutter/common/widgets/app_text.dart';

class CustomTextInput extends StatelessWidget {
  final String? topLabel;
  final String? placeholder;
  final TextEditingController controller;

  // Color parameters
  final Color? labelColor;
  final Color? hintColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? backgroundColor;

  // Size parameters
  final double? labelFontSize;
  final double? inputFontSize;
  final double? hintFontSize;
  final double? borderRadius;
  final double? borderWidth;
  final double? focusedBorderWidth;
  final EdgeInsetsGeometry? contentPadding;
  final double? spaceBetweenLabelAndInput;

  const CustomTextInput({
    super.key,
    this.topLabel,
    this.placeholder,
    required this.controller,
    // Color defaults
    this.labelColor,
    this.hintColor,
    this.borderColor,
    this.focusedBorderColor,
    this.backgroundColor,
    // Size defaults
    this.labelFontSize,
    this.inputFontSize,
    this.hintFontSize,
    this.borderRadius,
    this.borderWidth,
    this.focusedBorderWidth,
    this.contentPadding,
    this.spaceBetweenLabelAndInput,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topLabel != null) ...[
          AppText.bodyLarge(topLabel!, color: labelColor ?? RubyColors.black),
          SizedBox(height: spaceBetweenLabelAndInput ?? 8),
        ],
        TextField(
          controller: controller,
          style: TextStyle(fontSize: inputFontSize ?? 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: hintColor ?? RubyColors.grey,
              fontSize: hintFontSize ?? 14,
            ),
            filled: backgroundColor != null,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
              borderSide: BorderSide(
                color: borderColor ?? RubyColors.grey,
                width: borderWidth ?? 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
              borderSide: BorderSide(
                color: borderColor ?? RubyColors.grey,
                width: borderWidth ?? 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
              borderSide: BorderSide(
                color: focusedBorderColor ?? RubyColors.primary1,
                width: focusedBorderWidth ?? 2,
              ),
            ),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.heading5('Custom Text Input Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Standard styling
            CustomTextInput(
              topLabel: 'Assistant Email',
              placeholder: 'Type..',
              controller: _emailController,
            ),
            const SizedBox(height: 20),

            // Custom colors and sizes
            CustomTextInput(
              topLabel: 'Custom Styled Input',
              placeholder: 'Enter your name',
              controller: _nameController,
              labelColor: RubyColors.primary1,
              hintColor: RubyColors.grey,
              borderColor: RubyColors.purple,
              focusedBorderColor: RubyColors.purple,
              backgroundColor: RubyColors.purple,
              labelFontSize: 18,
              inputFontSize: 16,
              hintFontSize: 14,
              borderRadius: 12,
              borderWidth: 1.5,
              focusedBorderWidth: 3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              spaceBetweenLabelAndInput: 12,
            ),
            const SizedBox(height: 20),

            // Compact version
            CustomTextInput(
              placeholder: 'Compact input',
              controller: TextEditingController(),
              borderRadius: 4,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              inputFontSize: 12,
              hintFontSize: 12,
            ),
            const SizedBox(height: 20),

            // Button to demonstrate getting values
            ElevatedButton(
              onPressed: () {
                print('Email: ${_emailController.text}');
                print('Name: ${_nameController.text}');
              },
              child: AppText.bodyMedium('Get Values'),
            ),
          ],
        ),
      ),
    );
  }
}
